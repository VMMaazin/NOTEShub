#!/bin/bash
set -e

echo "=========================================================="
echo "  NOTEShub — Vercel Production Build for Flutter Web      "
echo "=========================================================="

# 1. Deterministic Flutter SDK Configuration
# Pins Flutter to the exact tested release (3.38.7) to prevent breaking changes
# from unpinned 'stable' updates. Can be overridden via Vercel env variable.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.7}"
FLUTTER_ROOT="${HOME}/flutter-${FLUTTER_VERSION}"

if [ ! -d "${FLUTTER_ROOT}" ]; then
  echo "==> Flutter SDK not found. Shallow cloning Flutter version ${FLUTTER_VERSION} into ${FLUTTER_ROOT}..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b "${FLUTTER_VERSION}" "${FLUTTER_ROOT}"
else
  echo "==> Found cached Flutter SDK at ${FLUTTER_ROOT}"
fi

export PATH="${FLUTTER_ROOT}/bin:${PATH}"

# 2. Display environment version info
echo "==> Using Flutter:"
flutter --version

# 3. Configure Flutter Web without prompt telemetry
echo "==> Configuring Flutter Web support..."
flutter config --enable-web --no-analytics

# 4. Resolve dependencies
echo "==> Fetching project dependencies..."
flutter pub get

# 5. Build Web Release bundle
echo "==> Compiling Flutter Web for release with root base-href..."
flutter build web --release --base-href /

# 6. Verify required artifact
if [ -f "build/web/index.html" ]; then
  echo "=========================================================="
  echo "  Build completed successfully!                           "
  echo "  Artifact directory: build/web                           "
  echo "  Entry point: build/web/index.html                       "
  echo "=========================================================="
else
  echo "==> Error: build/web/index.html was not generated!"
  exit 1
fi
