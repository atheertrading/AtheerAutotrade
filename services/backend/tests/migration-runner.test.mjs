import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  composeMigrationTransaction, discoverMigrations, sha256,
  stripTransactionWrapper, validateLocalServiceDefinition
} from "../scripts/migrate.mjs";

test("computes deterministic SHA-256", () => {
  assert.equal(sha256("atheer"), "544ad6179b013697f5b59d4e12db29dd4d83405b1670f9594c5692d2620e0662");
});

test("strips wrapper after comments and preserves comments", () => {
  const sql = "-- header\n/* note */\nBEGIN;\nSELECT 1;\nCOMMIT;";
  assert.equal(stripTransactionWrapper(sql), "-- header\n/* note */\nSELECT 1;");
  assert.throws(() => stripTransactionWrapper("SELECT 1;"), /outer BEGIN/);
});

test("discovers migrations in deterministic order", async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "atheer-migrations-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  await writeFile(join(directory, "0002_second.sql"), "BEGIN; SELECT 2; COMMIT;");
  await writeFile(join(directory, "0001_first.sql"), "-- header\nBEGIN; SELECT 1; COMMIT;");
  await writeFile(join(directory, "README.md"), "ignored");
  const migrations = await discoverMigrations(directory);
  assert.deepEqual(migrations.map((item) => item.version), ["0001_first", "0002_second"]);
  assert.equal(migrations[0].checksum, sha256(migrations[0].sql));
});

test("enforces local-only PostgreSQL service hosts", () => {
  assert.equal(validateLocalServiceDefinition("[atheer_dev]\nhost=127.0.0.1", "atheer_dev"), true);
  assert.equal(validateLocalServiceDefinition("[atheer_dev]\nhost=/tmp", "atheer_dev"), true);
  assert.equal(validateLocalServiceDefinition("[atheer_dev]\nhostaddr=::1", "atheer_dev"), true);
  assert.throws(() => validateLocalServiceDefinition("[atheer_dev]\nhost=db.example.com", "atheer_dev"), /local-only policy/);
  assert.throws(() => validateLocalServiceDefinition("[atheer_dev]\nhostaddr=10.0.0.5", "atheer_dev"), /local-only policy/);
  assert.throws(() => validateLocalServiceDefinition("[other]\nhost=localhost", "atheer_dev"), /was not found/);
});

test("runs each migration body only when its version/checksum is absent", () => {
  const sql = "-- migration comment\nBEGIN;\nCREATE TABLE example (id integer);\nCOMMIT;";
  const transaction = composeMigrationTransaction({ version: "0001_example", sql, checksum: sha256(sql) });
  assert.match(transaction, /pg_advisory_xact_lock/);
  assert.match(transaction, /checksum mismatch/);
  assert.match(transaction, /convert_from\(decode\('/);
  assert.match(transaction, /\\\\gexec/);
  assert.ok(transaction.includes("\\\\gexec"), "generated psql input must contain the literal \\gexec meta-command");
  assert.match(transaction, /CREATE TABLE IF NOT EXISTS atheer\.schema_migrations/);
  assert.match(transaction, /INSERT INTO atheer\.schema_migrations/);
  assert.match(transaction, /COMMIT;\n$/);
});

test("rejects unsafe migration identity and checksum", () => {
  assert.throws(() => composeMigrationTransaction({ version: "0001_bad'; DROP SCHEMA public;--", sql: "BEGIN; SELECT 1; COMMIT;", checksum: "a".repeat(64) }));
  assert.throws(() => composeMigrationTransaction({ version: "0001_valid", sql: "BEGIN; SELECT 1; COMMIT;", checksum: "invalid" }));
});
