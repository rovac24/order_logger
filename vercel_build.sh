#!/usr/bin/env bash
set -e

echo "Installing Flutter..."

FLUTTER_VERSION="3.19.6"

curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
  | tar xJ

# Fix Git safe directory issue (THIS IS THE KEY)
git config --global --add safe.directory /vercel/path0/flutter

export PATH="$PWD/flutter/bin:$PATH"

flutter config --no-enable-linux-desktop
flutter doctor -v

flutter pub get
flutter build web --release
