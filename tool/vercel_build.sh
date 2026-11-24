#!/usr/bin/env bash
# Build Flutter web for Vercel (root hosting, base-href=/).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.50.1}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"

echo "==> Flutter channel/version: ${FLUTTER_VERSION}"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "==> Cloning Flutter SDK into ${FLUTTER_DIR}"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "${FLUTTER_VERSION}" "${FLUTTER_DIR}"
else
  echo "==> Reusing existing Flutter at ${FLUTTER_DIR}"
  git -C "${FLUTTER_DIR}" fetch --depth 1 origin "${FLUTTER_VERSION}"
  git -C "${FLUTTER_DIR}" checkout --detach FETCH_HEAD
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --version
flutter config --no-analytics --enable-web
flutter precache --web

echo "==> pub get"
flutter pub get

echo "==> build web (release, base-href=/)"
flutter build web --release --no-pub --base-href /

echo "==> build/web ready"
test -s build/web/index.html
test -s build/web/flutter_bootstrap.js
ls -la build/web
