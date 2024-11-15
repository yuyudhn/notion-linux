#!/usr/bin/env bash
# Installs Notion to /opt/notion, sets up the launch script, and creates a desktop entry.

set -e

INSTALL_DIR="/opt/notion"
RELEASE_DIR="release/notion-linux"
DESKTOP_FILE_PATH="/usr/share/applications/notion.desktop"
ICON_PATH="$INSTALL_DIR/notion.png"  # Icon will be copied here

info() {
  echo -e "\\033[36mINFO\\033[0m:" "$@"
}

error() {
  echo -e "\\033[31mERROR\\033[0m:" "$@"
}

# Check if release directory exists
if [[ ! -d "$RELEASE_DIR" ]]; then
  echo "Error: Notion release directory '$RELEASE_DIR' not found. Build the app first."
  exit 1
fi

# Create the installation directory if it doesn't exist
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "Creating $INSTALL_DIR ..."
  sudo mkdir -p "$INSTALL_DIR"
fi

# Copy the release files to /opt/notion
info "Installing Notion to $INSTALL_DIR ..."
sudo cp -r "$RELEASE_DIR"/* "$INSTALL_DIR"

# Create the launch script directly as notion-linux
info "Creating the launch script as $INSTALL_DIR/notion-linux ..."
cat <<EOF | sudo tee "$INSTALL_DIR/notion-linux" > /dev/null
#!/usr/bin/env bash
# Launches Notion

if [[ ! -e "/opt/notion" ]]; then
  echo "Error: /opt/notion not found"
  exit 1
fi

cd /opt/notion || exit 1
exec ./electron app.asar
EOF

# Make the launch script executable
sudo chmod +x "$INSTALL_DIR/notion-linux"

# Copy the notion.png icon to /opt/notion
if [[ -f "notion.png" ]]; then
  echo "Copying notion.png to $INSTALL_DIR ..."
  sudo cp notion.png "$INSTALL_DIR/notion.png"
else
  error "Warning: No notion.png found in the current directory. Skipping icon setup."
fi

# Fix Broken XFCE Icon Image
sudo cp $INSTALL_DIR/notion.png /usr/share/pixmaps/notion.png

# Set appropriate permissions for all files
sudo chown -R root:root "$INSTALL_DIR"
sudo chmod -R 755 "$INSTALL_DIR"

# Create a symlink for notion-linux in /usr/local/bin
info "Creating symlink for notion-linux in /usr/local/bin ..."
sudo ln -sf "$INSTALL_DIR/notion-linux" /usr/local/bin/notion-linux

# Create the desktop entry for Notion
info "Creating desktop entry for Notion at $DESKTOP_FILE_PATH ..."
cat <<EOF | sudo tee "$DESKTOP_FILE_PATH" > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=Notion Desktop
Comment=Notion Desktop
Exec=$INSTALL_DIR/notion-linux
Icon=$ICON_PATH
StartupWMClass=notion
Categories=Office;TextEditor;Utility
Path=$INSTALL_DIR
Terminal=false
StartupNotify=false
EOF

# Set proper permissions for the desktop entry file
sudo chmod 644 "$DESKTOP_FILE_PATH"

info "Notion has been installed to $INSTALL_DIR, and the desktop entry has been created."
info "You can launch Notion from the application menu or by running 'notion-linux' from the terminal."
