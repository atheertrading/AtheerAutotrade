import { createHash } from "node:crypto";
import { readdir, readFile, stat } from "node:fs/promises";
import { spawn } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const SCRIPT_DIRECTORY = dirname(fileURLToPath(import.meta.url));
const DEFAULT_MIGRATIONS_DIRECTORY = resolve(SCRIPT_DIRECTORY, "../migrations");
const ADVISORY_LOCK_KEY = "734821906";
const LOOPBACK_HOSTS = new Set(["localhost", "127.0.0.1", "::1"]);

export function sha256(content) {
  return createHash("sha256").update(content, "utf8").digest("hex");
}

export function stripTransactionWrapper(sql) {
  const beginPattern = /^((?:(?:\s+)|(?:--[^\r\n]*(?:\r?\n|$))|(?:\/\*[\s\S]*?\*\/))*)BEGIN\s*;\s*/i;
  const beginMatch = beginPattern.exec(sql);
  const withoutBegin = beginMatch ? sql.slice(beginMatch[0].length) : sql;
  const commitPattern = /\s*COMMIT\s*;\s*$/i;
  const commitMatch = commitPattern.exec(withoutBegin);
  if (!beginMatch || !commitMatch) {
    throw new Error("Migration must contain one outer BEGIN; and COMMIT; wrapper.");
  }
  return `${beginMatch[1]}${withoutBegin.slice(0, commitMatch.index).trim()}`;
}

export function validateLocalServiceDefinition(contents, serviceName) {
  let activeSection = false;
  let foundSection = false;
  const settings = new Map();

  for (const rawLine of contents.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#") || line.startsWith(";")) continue;
    const section = /^\[([^\]]+)\]$/.exec(line);
    if (section) {
      activeSection = section[1] === serviceName;
      foundSection ||= activeSection;
      continue;
    }
    if (!activeSection) continue;
    const setting = /^([A-Za-z][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/.exec(line);
    if (setting) {
      const key = setting[1].toLowerCase();
      const value = setting[2].replace(/^(['"])(.*)\1$/, "$2").trim();
      settings.set(key, value);
    }
  }

  if (!foundSection) throw new Error(`PostgreSQL service "${serviceName}" was not found in PGSERVICEFILE.`);
  for (const key of ["host", "hostaddr"]) {
    const value = settings.get(key);
    if (!value) continue;
    const hosts = value.split(",").map((host) => host.trim().toLowerCase());
    if (hosts.some((host) => key === "host"
      ? !(LOOPBACK_HOSTS.has(host) || host.startsWith("/"))
      : !LOOPBACK_HOSTS.has(host))) {
      throw new Error("ATHEER local-only policy: PostgreSQL must use localhost, a loopback IP, or a local Unix socket.");
    }
  }
  return true;
}

export async function discoverMigrations(directory = DEFAULT_MIGRATIONS_DIRECTORY) {
  const names = (await readdir(directory)).filter((name) => /^\d{4}_[a-z0-9_]+\.sql$/.test(name)).sort();
  const migrations = [];
  for (const name of names) {
    const version = name.slice(0, -4);
    const sql = await readFile(join(directory, name), "utf8");
    if (sql.trim().length === 0) throw new Error(`Migration ${name} is empty.`);
    migrations.push(Object.freeze({ version, sql, checksum: sha256(sql) }));
  }
  return migrations;
}

export function composeMigrationTransaction(migration) {
  const version = migration.version;
  const checksum = migration.checksum;
  if (!/^\d{4}_[a-z0-9_]+$/.test(version) || !/^[0-9a-f]{64}$/.test(checksum)) {
    throw new Error("Invalid migration identity or checksum.");
  }
  const migrationSqlBase64 = Buffer.from(stripTransactionWrapper(migration.sql), "utf8").toString("base64");

  return `BEGIN;
SELECT pg_advisory_xact_lock(${ADVISORY_LOCK_KEY});

CREATE SCHEMA IF NOT EXISTS atheer;
CREATE TABLE IF NOT EXISTS atheer.schema_migrations (
  version varchar(128) PRIMARY KEY,
  checksum_sha256 varchar(64) NOT NULL
    CHECK (checksum_sha256 ~ '^[0-9a-f]{64}$'),
  applied_at_utc timestamptz NOT NULL DEFAULT now()
);

DO $atheer_migration_guard$
BEGIN
  IF EXISTS (
    SELECT 1 FROM atheer.schema_migrations
    WHERE version = '${version}' AND checksum_sha256 <> '${checksum}'
  ) THEN
    RAISE EXCEPTION 'Migration checksum mismatch for version %', '${version}';
  END IF;
END
$atheer_migration_guard$;

-- psql executes the migration body only if this exact version/checksum is absent.
SELECT CASE
  WHEN EXISTS (
    SELECT 1 FROM atheer.schema_migrations
    WHERE version = '${version}' AND checksum_sha256 = '${checksum}'
  ) THEN 'SELECT 1'
  ELSE convert_from(decode('${migrationSqlBase64}', 'base64'), 'UTF8')
END
\\gexec

INSERT INTO atheer.schema_migrations (version, checksum_sha256)
VALUES ('${version}', '${checksum}')
ON CONFLICT (version) DO NOTHING;

COMMIT;
`;
}

function requiredServiceConfiguration(environment) {
  const service = environment.PGSERVICE?.trim();
  const serviceFile = environment.PGSERVICEFILE?.trim();
  if (!service || !/^[A-Za-z0-9_.-]{1,64}$/.test(service)) throw new Error("PGSERVICE must name a configured PostgreSQL service.");
  if (!serviceFile) throw new Error("PGSERVICEFILE must point to a protected libpq service file.");
  return { service, serviceFile };
}

async function verifyServiceFile(serviceFile, service) {
  const metadata = await stat(serviceFile);
  if (!metadata.isFile()) throw new Error("PGSERVICEFILE must reference a regular file.");
  if ((metadata.mode & 0o077) !== 0) throw new Error("PGSERVICEFILE permissions are too broad; restrict access to its owner (for example chmod 600).");
  validateLocalServiceDefinition(await readFile(serviceFile, "utf8"), service);
}

function localLibpqEnvironment(environment) {
  return Object.fromEntries(Object.entries(environment).filter(([key]) => !/^PG(?!SERVICE$|SERVICEFILE$)/i.test(key)));
}

function executePsql(sql, environment) {
  return new Promise((resolvePromise, rejectPromise) => {
    const child = spawn(environment.PSQL_BIN?.trim() || "psql", [
      "--no-psqlrc", "--set=ON_ERROR_STOP=1", "--dbname",
      `service=${environment.PGSERVICE}`, "--file", "-"
    ], {
      env: { ...localLibpqEnvironment(environment), PGSERVICE: environment.PGSERVICE, PGSERVICEFILE: environment.PGSERVICEFILE },
      stdio: ["pipe", "inherit", "inherit"]
    });
    child.once("error", () => rejectPromise(new Error("Could not start psql. Install PostgreSQL client tools and verify PATH.")));
    child.once("close", (code) => code === 0
      ? resolvePromise()
      : rejectPromise(new Error(`PostgreSQL migration process failed (exit code ${code ?? "unknown"}).`)));
    child.stdin.end(sql);
  });
}

export async function runMigrations({ directory = DEFAULT_MIGRATIONS_DIRECTORY, environment = process.env } = {}) {
  const { service, serviceFile } = requiredServiceConfiguration(environment);
  await verifyServiceFile(serviceFile, service);
  const migrations = await discoverMigrations(directory);
  if (migrations.length === 0) throw new Error("No versioned SQL migrations were found.");
  for (const migration of migrations) {
    console.log(`Applying/checking migration ${migration.version} (${migration.checksum.slice(0, 12)}…)`);
    await executePsql(composeMigrationTransaction(migration), environment);
  }
  console.log(`Migration check complete: ${migrations.length} migration(s) processed.`);
}

const invokedPath = process.argv[1] ? resolve(process.argv[1]) : "";
if (invokedPath && pathToFileURL(invokedPath).href === import.meta.url) {
  runMigrations().catch((error) => {
    console.error(`Database migration failed: ${error.message}`);
    process.exitCode = 1;
  });
}
