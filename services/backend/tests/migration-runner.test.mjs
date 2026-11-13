import assert from "node:assert/strict";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  composeMigrationTransaction,
  discoverMigrations,
  sha256,
  stripTransactionWrapper
} from "../scripts/migrate.mjs";

test("computes a deterministic SHA-256 checksum", () => {
  assert.equal(
    sha256("atheer"),
    "5b6d3e6c8f3c2b3f7e7d0e3f1f3e3e5f3e2e3d4c5b6a79808192a3b4c5d6e7f8".slice(0, 64)
  );
});

test("requires and removes the migration transaction wrapper", () => {
  assert.equal(stripTransactionWrapper("BEGIN;\nSELECT 1;\nCOMMIT;"), "SELECT 1;");
  assert.throws(() => stripTransactionWrapper("SELECT 1;"), /outer BEGIN/);
});

test("discovers migrations in deterministic version order and ignores non-migration files", async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "atheer-migrations-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  await writeFile(join(directory, "0002_second.sql"), "BEGIN; SELECT 2; COMMIT;");
  await writeFile(join(directory, "0001_first.sql"), "BEGIN; SELECT 1; COMMIT;");
  await writeFile(join(directory, "README.md"), "not a migration");

  const migrations = await discoverMigrations(directory);
  assert.deepEqual(migrations.map((migration) => migration.version), [
    "0001_first",
    "0002_second"
  ]);
  assert.equal(migrations[0].checksum, sha256(migrations[0].sql));
});

test("wraps migration and checksum record in one advisory-locked transaction", () => {
  const sql = "BEGIN;\nCREATE TABLE example (id integer);\nCOMMIT;";
  const transaction = composeMigrationTransaction({
    version: "0001_example",
    sql,
    checksum: sha256(sql)
  });

  assert.match(transaction, /pg_advisory_xact_lock/);
  assert.match(transaction, /checksum mismatch/);
  assert.match(transaction, /CREATE TABLE example/);
  assert.match(transaction, /INSERT INTO atheer\.schema_migrations/);
  assert.match(transaction, /ON CONFLICT \(version\) DO NOTHING/);
  assert.match(transaction, /^BEGIN;/);
  assert.match(transaction, /COMMIT;\n$/);
});

test("rejects unsafe migration identities and malformed checksums", () => {
  assert.throws(() => composeMigrationTransaction({
    version: "0001_bad'; DROP SCHEMA public;--",
    sql: "BEGIN; SELECT 1; COMMIT;",
    checksum: "a".repeat(64)
  }));
  assert.throws(() => composeMigrationTransaction({
    version: "0001_valid",
    sql: "BEGIN; SELECT 1; COMMIT;",
    checksum: "invalid"
  }));
});
