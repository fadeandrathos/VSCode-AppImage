#!/bin/bash
set -e

APP="VSCode"
ARCH="x86_64"
APPDIR="${APP}.AppDir"

WORKDIR=$(mktemp -d)
trap 'echo "--> Cleaning up temporary directory..."; rm -r "$WORKDIR"' EXIT
cd "$WORKDIR"

echo "✅ Downloading necessary files..."
wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O appimagetool
chmod +x appimagetool

wget -q "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -O vscode.deb

echo "📦 Extracting package..."
ar x vscode.deb
tar xf data.tar.xz

echo "🏗️ Assembling the AppDir..."
mv ./usr/share/code ./"$APPDIR"

echo "🚀 Creating the AppRun entrypoint..."
cat <<'EOF' > ./"$APPDIR"/AppRun
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/code" "$@"
EOF
chmod +x ./"$APPDIR"/AppRun

echo "🎨 Setting up icons and desktop entry..."
cp ./"$APPDIR"/resources/app/resources/linux/code.png ./"$APPDIR"/vscode.png
cp ./usr/share/applications/code.desktop ./"$APPDIR"/vscode.desktop
sed -i 's|/usr/share/code/code|AppRun|g' ./"$APPDIR"/vscode.desktop

echo "🔎 Determining application version..."
VERSION=$(dpkg-deb -f vscode.deb Version)
APPIMAGE_NAME="$APP-$VERSION-$ARCH.AppImage"

echo "Building $APPIMAGE_NAME..."

ARCH=x86_64 ./appimagetool \
  --comp zstd \
  --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
  ./"$APPDIR" \
  "$APPIMAGE_NAME"

echo "🎉 Build complete!"
mv "$APPIMAGE_NAME" "$OLDPWD"
echo "AppImage created at: $(realpath "$OLDPWD/$APPIMAGE_NAME")"

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "appimage_name=$APPIMAGE_NAME" >> "$GITHUB_OUTPUT"