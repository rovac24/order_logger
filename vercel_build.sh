#!/bin/bash

# Install Flutter dependencies for Linux
apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    libgtk-3-dev \
    clang \
    pkg-config \
    liblzma-dev \
    libstdc++-12-dev \
    libglu1-mesa-dev

# Fix git ownership issue
git config --global --add safe.directory /vercel/path0/flutter

# Clean and repair pub cache
dart pub cache repair

# Get dependencies
flutter pub get

# Build for web
flutter build web --release --web-renderer canvaskit --no-tree-shake-icons

# Copy build output to vercel's expected directory
cp -r build/web/* public/