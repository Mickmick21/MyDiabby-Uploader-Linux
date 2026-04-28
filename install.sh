#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="$SCRIPT_DIR/files"
INSTALL_DIR="/opt/mydiabby-uploader"
ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
DESKTOP_FILE="/usr/share/applications/mydiabby-uploader.desktop"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

echo "Installing myDiabby Uploader..."

mkdir -p "$INSTALL_DIR"
cp -r "$FILES_DIR"/. "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/mydiabby-uploader"

mkdir -p "$ICON_DIR"
cp "$FILES_DIR/icon.png" "$ICON_DIR/mydiabby-uploader.png"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=myDiabby Uploader
Exec=$INSTALL_DIR/mydiabby-uploader --enable-experimental-web-platform-features
Icon=mydiabby-uploader
Type=Application
Categories=MedicalSoftware;Science;
Comment=Upload your device's data to myDiabby
Terminal=false
EOF

gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

if [ -n "$SUDO_USER" ]; then
  usermod -a -G uucp,dialout,plugdev "$SUDO_USER"
  echo "Added $SUDO_USER to uucp, dialout and plugdev groups."
  echo "Please log out and back in for group changes to take effect."
fi

echo "Installation complete."
