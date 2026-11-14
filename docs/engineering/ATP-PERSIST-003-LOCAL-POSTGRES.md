# ATP-PERSIST-003 — Local PostgreSQL enforcement and migration runner correctness

**Status:** Ported to current main; migration-runner CI pending; PostgreSQL remains NOT IMPLEMENTED operationally.

## Defects corrected

- The original SQL migration has leading comments before `BEGIN;`; the first runner parser rejected that real migration. The parser now supports and preserves leading line/block comments.
- The original runner executed the migration body again even when the same version/checksum was already recorded. The runner now skips an already-applied identical migration and still rejects a changed checksum.
- The owner selected PostgreSQL on the development Mac as the sole database target for the current phase. The runner now rejects remote `host` and `hostaddr` service definitions.
- Libpq environment overrides are removed before spawning `psql`, preventing `PGHOST` / `PGHOSTADDR` from redirecting a named local service.

## Local database contract

PostgreSQL server and database files remain on the owner's Mac. Only localhost, loopback IP addresses, or a local Unix-domain socket are accepted. No cloud or remote database is used in this phase. Any later cloud migration requires a separate design review and owner approval. Capital.com broker connectivity remains external and is not affected by the local persistence requirement.

## Verification boundary

Unit tests cover comment-aware wrapper parsing, deterministic discovery, checksum generation, local endpoint enforcement, and skip-on-rerun transaction composition. They do not prove a PostgreSQL server is installed, running, or migrated on the owner's Mac. Real PostgreSQL tests remain pending: initial application, no-op rerun, checksum mismatch, rollback, and concurrent runner behavior.

## Change log

- 2026-11-13: Original feature-branch implementation corrected migration bootstrap parsing, repeat-application behavior, and local-only database enforcement.
- 2026-11-14: Ported to a branch based on current main. Fixed JavaScript template-literal escaping so generated psql input contains the required literal `\\gexec` command; strengthened the unit assertion to verify the actual output. No PostgreSQL server was provisioned and no migration was applied.
