#!/usr/bin/env bash
# Build Flutter web for Vercel (root hosting, base-href=/).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"

echo "==> Flutter channel/version: ${FLUTTER_VERSION}"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "==> Cloning Flutter SDK into ${FLUTTER_DIR}"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "${FLUTTER_VERSION}" "${FLUTTER_DIR}"
else
  echo "==> Reusing existing Flutter at ${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --version
flutter config --no-analytics --enable-web
flutter precache --web

echo "==> pub get"
flutter pub get

echo "==> build web (release, base-href=/)"
flutter build web --release --base-href /

echo "==> build/web ready"
ls -la build/web | head -n 30
