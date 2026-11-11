#!/bin/bash
set -e

echo "=========================================================="
echo "  NOTEShub — Vercel Production Build for Flutter Web      "
echo "=========================================================="

# 1. Ensure Flutter SDK is available
if command -v flutter >/dev/null 2>&1; then
  echo "==> Detected system Flutter SDK: $(flutter --version | head -n 1)"
else
  FLUTTER_ROOT="${HOME}/flutter"
  if [ ! -d "${FLUTTER_ROOT}" ]; then
    echo "==> Flutter SDK not found. Shallow cloning Flutter stable into ${FLUTTER_ROOT}..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "${FLUTTER_ROOT}"
  else
    echo "==> Found cached Flutter SDK at ${FLUTTER_ROOT}"
  fi
  export PATH="${PATH}:${FLUTTER_ROOT}/bin"
fi

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

