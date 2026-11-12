# macOS Backend Bundle Layout

**Status:** Xcode packaging phase and script are implemented in source; build and signature verification pending.

## Required application bundle paths

The native supervisor resolves only these fixed paths:

    AtheerAutotrade.app/
    └── Contents/
        ├── MacOS/
        │   └── AtheerAutotrade
        ├── Helpers/
        │   └── AtheerNodeRuntime/
        │       └── bin/
        │           └── node
        └── Resources/
            └── Backend/
                ├── package.json
                └── dist/
                    ├── server.js
                    └── ...

- Node executable: Contents/Helpers/AtheerNodeRuntime/bin/node
- Backend entry point: Contents/Resources/Backend/dist/server.js
- Launch arguments: absolute backend entry-point path and --transport=stdio.
- Child working directory: backend dist directory.
- Child environment: explicitly reduced to NODE_ENV=production.
- No shell is invoked at application runtime. No PATH lookup occurs at application runtime. No credentials are supplied in arguments or environment variables.

## Build integration

- Xcode app target includes the Package Backend Runtime shell-script build phase.
- The phase invokes apps/macos/Scripts/package-backend.sh.
- The script requires Node.js 24 and a universal x86_64 + arm64 executable at build time.
- The script runs npm ci when the lockfile marker is absent/stale, runs the strict TypeScript build, copies the Node executable and compiled backend into the bundle, and signs the nested Node executable when Xcode code signing is enabled with a signing identity.
- ATHEER_NODE_BINARY may be supplied as a build setting/environment override for the exact Node executable. The normal runtime does not use that path; it launches the bundled copy.

## Remaining release requirements

1. Pin and record an exact Node.js 24 patch version and checksum rather than relying only on the major-version check.
2. Verify the Node runtime's source and universal architecture before release.
3. Verify nested Node and outer app signatures with the intended Developer ID/Apple Development identity.
4. Verify hardened-runtime, library-validation, Gatekeeper, and notarization behavior.
5. Verify that the final app contains no credentials, development configuration, node_modules, or unnecessary build artifacts.
6. Verify launch, protocol v2 handshake, X25519/HKDF/AES-GCM interoperability, timeout, child crash, shutdown, and restart on the target Mac.
7. Test x86_64 on Intel and arm64 on Apple Silicon; do not infer one architecture's result from the other.

## Current implementation boundary

- The Swift supervisor resolves only the fixed paths and launches the child using anonymous stdio pipes.
- Protocol v2 implements encrypted one-shot credential handoff, read-only Capital.com Demo session creation/ping, session status, market search, and historical prices.
- The Xcode packaging phase and script are present but have not been executed in the target environment.
- The Node runtime is not committed to Git; it is copied from a locally installed Node.js 24 universal executable during build.
- No target-Mac build, nested signature verification, packaged child launch, or actual Capital.com Demo authentication has been verified.
- WebSocket streaming is implemented in the adapter but is not yet exposed through IPC or consumed by the macOS UI.
- No account mutation, orders, dealing, execution, or LIVE capability is exposed.

Do not treat the existence of the build phase or Swift supervisor as proof that the packaged broker connection works. Build, cryptographic interoperability, runtime launch, and broker authentication are separate acceptance gates.
