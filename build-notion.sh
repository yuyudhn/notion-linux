#!/usr/bin/env bash
# Creates a distributable Notion Linux app from .dmg for Linux.

set -eo pipefail

# Configuration variables
OS="linux"
ARCH="x64"
NOTION_VERSION="3.9.1"
BETTER_SQLITE3_VERSION="9.4.5"
BUILD_DIR="build"
RELEASE_DIR="release"

info() {
  echo -e "\\033[36mINFO\\033[0m:" "$@"
}

error() {
  echo -e "\\033[31mERROR\\033[0m:" "$@"
}

download_notion() {
  if [[ ! -e "src/notion-$NOTION_VERSION.dmg" ]]; then
    info "Downloading Notion $NOTION_VERSION ..."
    wget -q "https://desktop-release.notion-static.com/Notion-$NOTION_VERSION.dmg" -O "src/notion-$NOTION_VERSION.dmg"
  fi
}

extract_dmg() {
  info "Extracting Notion.dmg ..."
  rm -rf "$BUILD_DIR/notion" 2>/dev/null || true
  mkdir -p "$BUILD_DIR/notion" 2>/dev/null || true
  7z x "src/notion-$NOTION_VERSION.dmg" -y -o"$BUILD_DIR/notion" >/dev/null 2>&1 || true
}

detect_electron_version() {
  if [[ -z "$ELECTRON_VERSION" ]]; then
    info "Detecting Electron version from Notion ..."
    
    # The fixed path to Electron Framework in the extracted DMG
    ELECTRON_FRAMEWORK_PATH="$BUILD_DIR/notion/Notion/Notion.app/Contents/Frameworks/Electron Framework.framework/Electron Framework"
    
    if [[ -e "$ELECTRON_FRAMEWORK_PATH" ]]; then
      ELECTRON_VERSION=$(strings "$ELECTRON_FRAMEWORK_PATH" |
        grep "Chrome/" | grep -i Electron | grep -v '%s' | sort -u | cut -f 3 -d '/')
      
      ELECTRON_VERSION="v$ELECTRON_VERSION"
      info "Detected Electron version: $ELECTRON_VERSION"
    else
      error "Electron Framework file not found."
      exit 1
    fi
  fi
}

download_electron() {
  info "Ensuring electron $ELECTRON_VERSION ..."
  if [[ ! -e "src/electron-$ELECTRON_VERSION.zip" ]]; then
    wget -q "https://github.com/electron/electron/releases/download/$ELECTRON_VERSION/electron-$ELECTRON_VERSION-linux-$ARCH.zip" -O "src/electron-$ELECTRON_VERSION.zip"
  fi
}

download_better_sqlite3() {
  better_sqlite3_filename="better-sqlite3-v$BETTER_SQLITE3_VERSION-electron-v121-linux-$ARCH.tar.gz"
  if [[ ! -e "$node_binding_target" ]]; then
    wget -q "https://github.com/WiseLibs/better-sqlite3/releases/download/v$BETTER_SQLITE3_VERSION/$better_sqlite3_filename" -O "src/$better_sqlite3_filename"
    tar -xzf "src/$better_sqlite3_filename" -C "src"
  fi
}

extract_electron() {
  info "Extracting Electron ..."
  rm -rf "$BUILD_DIR/electron" 2>/dev/null || true
  mkdir -p "$BUILD_DIR/electron" 2>/dev/null || true
  7z x "src/electron-$ELECTRON_VERSION.zip" -y -o"$BUILD_DIR/electron" >/dev/null
}

prepare_app_path() {
  appExtractPath="$BUILD_DIR/electron/resources"
}

copy_files_to_electron() {
  info "Copying necessary files to Electron app ..."
  cp -rp $BUILD_DIR/notion/Notion/Notion.app/Contents/Resources/{app.asar.unpacked,app.asar} "$appExtractPath"
  cp "src/build/Release/better_sqlite3.node" "$appExtractPath/app.asar.unpacked/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
}

build_app() {
  info "Building Notion app for Linux ..."
  mkdir -p "$RELEASE_DIR/notion-linux"
  cp -r "$BUILD_DIR/electron"/* "$RELEASE_DIR/notion-linux/"
  cp -r "$BUILD_DIR/notion/Notion/Notion.app/Contents/Resources"/* "$RELEASE_DIR/notion-linux/"
}

if ! command -v 7z >/dev/null; then
  error "7z not installed. Run 'sudo apt install 7zip' to install it."
  exit 1
fi

rm -rf src build release 2>/dev/null || true
mkdir -p src build release 2>/dev/null || true

# Build Notion Linux....
download_notion
extract_dmg
detect_electron_version
download_electron
download_better_sqlite3
extract_electron

prepare_app_path
copy_files_to_electron
build_app

info "Notion app is ready in 'release/notion-linux'."
