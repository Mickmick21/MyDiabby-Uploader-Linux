#!/bin/bash

INSTALL_DIR="/opt/mydiabby-uploader"
ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
DESKTOP_FILE="/usr/share/applications/mydiabby-uploader.desktop"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./uninstall.sh)"
  exit 1
fi

echo "Uninstalling myDiabby Uploader..."

if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  echo "Removed $INSTALL_DIR"
fi

if [ -f "$ICON_DIR/mydiabby-uploader.png" ]; then
  rm -f "$ICON_DIR/mydiabby-uploader.png"
  echo "Removed icon"
fi

# Remove desktop entry
if [ -f "$DESKTOP_FILE" ]; then
  rm -f "$DESKTOP_FILE"
  echo "Removed desktop entry"
fi

gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

echo "Uninstallation complete."
echo "Note: $SUDO_USER was not removed from dialout/plugdev groups."
echo "To do so manually run: sudo gpasswd -d $SUDO_USER dialout && sudo gpasswd -d $SUDO_USER plugdev"
