# macOS Backend Bundle Layout

**Status:** Packaging contract only; copy phases, runtime artifact, and signature verification are not implemented.

## Required application bundle paths

The native supervisor resolves these fixed paths relative to the signed application bundle:

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
                └── dist/
                    ├── server.js
                    └── api/
                        └── ...

- Node executable: Contents/Helpers/AtheerNodeRuntime/bin/node
- Backend entry point: Contents/Resources/Backend/dist/server.js
- Launch arguments: the absolute backend entry-point path and --transport=stdio.
- The child working directory is the backend dist directory.
- The child environment is explicitly reduced to NODE_ENV=production.
- No shell is invoked, no executable is resolved through PATH, and no credentials are supplied in arguments or environment variables.

The compiled backend directory must preserve the relative module layout emitted by the backend TypeScript compiler. The current Node backend uses Node.js 24 and emits ESM into services/backend/dist.

## Signing and packaging requirements

1. Pin and record the exact Node.js 24 patch release and source checksum.
2. Package only the required runtime files; do not download or resolve a runtime during application launch.
3. Sign the Node executable and any nested native runtime components before signing the containing application.
4. Sign the outer application after all helper and resource files have been copied.
5. Verify the final app signature and nested-code signatures on the target macOS release.
6. Verify the executable architecture matches the app process architecture. Intel x86_64 is the first required runtime target; arm64 remains unverified until tested.
7. Verify launch, handshake, clean EOF, child crash, timeout, and relaunch using the packaged artifact.
8. Ensure release packaging does not introduce broker credentials, tokens, or development configuration.

## Current implementation boundary

- The Swift supervisor has been authored to resolve only the fixed paths above and launch the child with anonymous stdio pipes.
- The Xcode project includes the Swift source files, but no build phase currently copies Node.js or backend output into the bundle.
- No Node runtime binary has been committed or downloaded by this work.
- No code-signature verification has been implemented in the supervisor.
- The supervisor is not yet connected to the SwiftUI application lifecycle.
- Keychain ownership and credential transfer remain out of scope. The current IPC capability set remains limited to system.hello and system.ping.

Do not treat the presence of the Swift source as proof that the packaged backend can launch. Packaging and runtime verification are separate acceptance gates.
