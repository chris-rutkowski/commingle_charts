#!/usr/bin/env bash
#
# Run the tests inside the exact same Linux container image that CI uses, forced
# to linux/amd64 so golden rasterization matches the x86_64 CI runner
# byte-for-byte. This is what makes goldens platform-independent between your Mac
# and GitHub Actions.
#
# Requires Docker (Docker Desktop or Colima). On Apple Silicon the linux/amd64
# platform runs under emulation (QEMU/Rosetta), so the first run is slower.
#
# Any arguments are forwarded to `flutter test`, so the same script covers both
# verifying and regenerating goldens:
#
#   scripts/containerised_test.sh                    # run tests (verify goldens)
#   scripts/containerised_test.sh --update-goldens   # regenerate goldens in place
#   scripts/containerised_test.sh test/pie           # forward any flutter test args
#
set -euo pipefail

# Pinned by digest so this and .github/workflows/test.yml resolve to the
# identical image. Keep in sync with the workflow's container.image.
IMAGE="ghcr.io/adrianjagielak/flutter:3.44.2@sha256:8e2fb6903d05fb8c7fdd5c218f7d7953e74315b1f918355310ac2017738f9e23"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker not found. Install Docker Desktop or Colima first." >&2
  exit 1
fi

# Notes on the mounts:
#   -v REPO:/app              bind the repo so generated goldens land on the host
#   -v /app/.dart_tool        anonymous volume shields the host's macOS .dart_tool
#   -v pubcache volume        persist pub deps across runs to speed things up
#
# Forwarded args ("$@") are passed positionally into the inner shell so quoting
# and paths survive intact.
exec docker run --rm \
  --platform linux/amd64 \
  -e PUB_CACHE=/pub-cache \
  -v commingle_charts_pubcache:/pub-cache \
  -v "${REPO_ROOT}:/app" \
  -v /app/.dart_tool \
  -w /app \
  "${IMAGE}" \
  bash -lc 'git config --global --add safe.directory "*" && flutter pub get && flutter test --reporter=failures-only "$@"' _ "$@"
