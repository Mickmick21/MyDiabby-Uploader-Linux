#!/bin/bash

# Usage: ./update.sh <path_to_new_windows_app_directory>
# Example: ./update.sh ~/Downloads/myDiabby-Uploader-2.42.0-win/resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_NODES_DIR="$SCRIPT_DIR/linux-nodes"
WORK_DIR="$(mktemp -d)"
NEW_WIN_RESOURCES="$1"

# Cleanup on exit
trap 'rm -rf "$WORK_DIR"' EXIT

# Check arguments
if [ -z "$NEW_WIN_RESOURCES" ]; then
  echo "Usage: $0 <path_to_new_windows_resources_directory>"
  echo "Example: $0 ~/Downloads/myDiabby-Uploader-2.42.0-win/resources"
  exit 1
fi

# Check new asar exists
if [ ! -f "$NEW_WIN_RESOURCES/app.asar" ]; then
  echo "Error: app.asar not found in $NEW_WIN_RESOURCES"
  exit 1
fi

# Check linux nodes directory exists
if [ ! -d "$LINUX_NODES_DIR" ]; then
  echo "Error: linux-nodes directory not found at $LINUX_NODES_DIR"
  echo "Please create it and populate it with your Linux-built .node files:"
  echo "  $LINUX_NODES_DIR/drivelist.node"
  echo "  $LINUX_NODES_DIR/keytar.node"
  echo "  $LINUX_NODES_DIR/usb_bindings.node"
  echo "  $LINUX_NODES_DIR/direct-io.node"
  exit 1
fi

# Check all required Linux binaries exist
for f in drivelist.node keytar.node usb_bindings.node direct-io.node; do
  if [ ! -f "$LINUX_NODES_DIR/$f" ]; then
    echo "Error: missing $f in $LINUX_NODES_DIR"
    exit 1
  fi
done

echo "==> Copying new asar files to work directory..."
cp "$NEW_WIN_RESOURCES/app.asar" "$WORK_DIR/app.asar.new"
if [ -d "$NEW_WIN_RESOURCES/app.asar.unpacked" ]; then
  cp -r "$NEW_WIN_RESOURCES/app.asar.unpacked" "$WORK_DIR/app.asar.new.unpacked"
fi

echo "==> Extracting new asar..."
cd "$WORK_DIR"
npx asar extract app.asar.new app.asar.extracted

echo "==> Replacing Windows binaries with Linux builds..."
cp "$LINUX_NODES_DIR/drivelist.node" \
   "$WORK_DIR/app.asar.extracted/node_modules/drivelist/build/Release/drivelist.node"

cp "$LINUX_NODES_DIR/keytar.node" \
   "$WORK_DIR/app.asar.extracted/node_modules/keytar/build/Release/keytar.node"

cp "$LINUX_NODES_DIR/usb_bindings.node" \
   "$WORK_DIR/app.asar.extracted/node_modules/usb/build/Release/usb_bindings.node"

cp "$LINUX_NODES_DIR/direct-io.node" \
   "$WORK_DIR/app.asar.extracted/node_modules/@tidepool/direct-io/build/Release/binding.node"

cp "$LINUX_NODES_DIR/direct-io.node" \
   "$WORK_DIR/app.asar.extracted/node_modules/@tidepool/direct-io/binding.node"

echo "==> Verifying no Windows binaries remain..."
REMAINING=$(find "$WORK_DIR/app.asar.extracted/node_modules" -name "*.node" | \
  xargs file | grep "PE32" | grep -v "prebuilds/win32" || true)

if [ -n "$REMAINING" ]; then
  echo "Warning: Windows binaries still present:"
  echo "$REMAINING"
  read -p "Continue anyway? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
else
  echo "All binaries are Linux ELF. Good."
fi

echo "==> Repacking asar..."
npx asar pack "$WORK_DIR/app.asar.extracted" "$WORK_DIR/app.asar.final"

echo "==> Installing updated asar..."
if [ "$EUID" -ne 0 ]; then
  echo "Need sudo to copy to /opt/mydiabby-uploader/resources/"
  sudo cp "$WORK_DIR/app.asar.final" /opt/mydiabby-uploader/resources/app.asar
else
  cp "$WORK_DIR/app.asar.final" /opt/mydiabby-uploader/resources/app.asar
fi

echo "==> Done! myDiabby Uploader has been updated."
