#!/bin/bash
set -euo pipefail

REPOSITORY_ROOT="$(cd "${SRCROOT}/../.." && pwd)"
BACKEND_ROOT="${REPOSITORY_ROOT}/services/backend"
NODE_SOURCE="${ATHEER_NODE_BINARY:-$(command -v node || true)}"
if [[ -z "${NODE_SOURCE}" && -x "/usr/local/bin/node" ]]; then
  NODE_SOURCE="/usr/local/bin/node"
fi
if [[ -z "${NODE_SOURCE}" && -x "/opt/homebrew/bin/node" ]]; then
  NODE_SOURCE="/opt/homebrew/bin/node"
fi

if [[ -z "${NODE_SOURCE}" || ! -x "${NODE_SOURCE}" ]]; then
  echo "error: Node.js 24 is required to package the ATHEER backend runtime." >&2
  exit 1
fi

export PATH="$(dirname "${NODE_SOURCE}"):${PATH}"
NODE_MAJOR="$("${NODE_SOURCE}" -p 'process.versions.node.split(".")[0]')"
if [[ "${NODE_MAJOR}" != "24" ]]; then
  echo "error: ATHEER backend requires Node.js 24.x; found $("${NODE_SOURCE}" --version)." >&2
  exit 1
fi

NODE_ARCHS="$(lipo -archs "${NODE_SOURCE}")"
for REQUIRED_ARCH in x86_64 arm64; do
  if [[ " ${NODE_ARCHS} " != *" ${REQUIRED_ARCH} "* ]]; then
    echo "error: bundled Node.js runtime must support both x86_64 and arm64; found ${NODE_ARCHS}." >&2
    exit 1
  fi
done

LOCK_HASH="$(shasum -a 256 "${BACKEND_ROOT}/package-lock.json" | awk '{print $1}')"
LOCK_MARKER="${BACKEND_ROOT}/node_modules/.atheer-package-lock-sha"
if [[ ! -x "${BACKEND_ROOT}/node_modules/.bin/tsc" ]] || [[ ! -f "${LOCK_MARKER}" ]] || [[ "$(cat "${LOCK_MARKER}")" != "${LOCK_HASH}" ]]; then
  npm ci --include=dev --prefix "${BACKEND_ROOT}"
  mkdir -p "${BACKEND_ROOT}/node_modules"
  printf '%s' "${LOCK_HASH}" > "${LOCK_MARKER}"
fi

npm run build --prefix "${BACKEND_ROOT}"

NODE_DEST="${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Helpers/AtheerNodeRuntime/bin/node"
BACKEND_DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Backend"

mkdir -p "$(dirname "${NODE_DEST}")" "${BACKEND_DEST}"
cp -L "${NODE_SOURCE}" "${NODE_DEST}"
chmod 755 "${NODE_DEST}"
rm -rf "${BACKEND_DEST}/dist"
mkdir -p "${BACKEND_DEST}/dist"
cp -R "${BACKEND_ROOT}/dist/." "${BACKEND_DEST}/dist/"
cp "${BACKEND_ROOT}/package.json" "${BACKEND_DEST}/package.json"

if [[ "${CODE_SIGNING_ALLOWED:-NO}" == "YES" ]]; then
  SIGNING_IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:--}"
  codesign --force --options runtime --timestamp=none --sign "${SIGNING_IDENTITY}" "${NODE_DEST}"
  codesign --verify --strict "${NODE_DEST}"
fi

echo "Packaged Node.js $("${NODE_DEST}" --version) and ATHEER backend into the application bundle."
