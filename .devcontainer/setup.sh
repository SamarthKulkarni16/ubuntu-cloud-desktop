#!/usr/bin/env bash
set -e

echo "Updating package lists..."
sudo apt-get update -y

echo "Installing XFCE desktop, VNC server, and noVNC..."
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< "tzdata tzdata/Areas select Asia"
sudo debconf-set-selections <<< "tzdata tzdata/Zones/Asia select Kolkata"
sudo -E apt-get install -y \
  xfce4 \
  xfce4-goodies \
  tigervnc-standalone-server \
  tigervnc-common \
  novnc \
  websockify \
  dbus-x11 \
  x11-xserver-utils \
  gedit \
  unzip \
  wget \
  curl \
  software-properties-common \
  epiphany-browser

# --- Critical desktop config: must always complete, regardless of what      ---
# --- happens later (e.g. Firefox download flaking). Do this BEFORE anything ---
# --- optional/network-fragile, so a failure downstream can never leave the  ---
# --- desktop half-configured.                                              ---

echo "Setting up VNC password..."
mkdir -p ~/.vnc
echo "ubuntu" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

echo "Configuring XFCE as the VNC session..."
cat > ~/.vnc/xstartup << 'XSTART'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
XSTART
chmod +x ~/.vnc/xstartup

echo "Core desktop setup complete."

# --- Optional / network-fragile step: Firefox. Isolated so a failure here  ---
# --- (flaky download, redirect issue, rate limit, etc.) can NEVER take     ---
# --- down the rest of the script or block start-desktop.sh from running.   ---

echo "Installing real Firefox via the Mozilla Team PPA (avoids both the broken"
echo "Ubuntu snap redirect AND the unreliable download.mozilla.org CDN, which"
echo "does not download reliably on the Codespaces network)..."
(
  set +e  # failures in this subshell must not kill the parent script

  # Remove Ubuntu's firefox stub package if present - it's the thing that
  # prints "requires the firefox snap to be installed" when you run firefox.
  sudo apt-get remove -y firefox >/dev/null 2>&1

  sudo add-apt-repository -y ppa:mozillateam/ppa

  # Pin so apt prefers the PPA's real .deb over Ubuntu's snap-redirect stub.
  cat <<'PIN' | sudo tee /etc/apt/preferences.d/mozilla-firefox > /dev/null
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
PIN

  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y firefox

  if command -v firefox >/dev/null 2>&1 && firefox --version >/dev/null 2>&1; then
    echo "  Firefox installed successfully via PPA: $(firefox --version)"
  else
    echo "  WARNING: Firefox PPA install did not produce a working firefox binary. Skipping Firefox install."
    echo "  You can retry later from inside the desktop terminal with:"
    echo "    sudo apt-get update && sudo apt-get install -y firefox"
    echo "  In the meantime, Epiphany (GNOME Web) is installed as a working fallback browser."
    echo "  Launch it from the dock, or run: epiphany"
  fi

  exit 0
)
echo "Firefox step finished (see above for outcome)."
echo "A guaranteed-working fallback browser (Epiphany / GNOME Web) is also installed - launch with: epiphany"

# --- Register a real default browser so XFCE's dock/panel "Web Browser"    ---
# --- icon actually launches something. That icon is a GENERIC launcher    ---
# --- (exo's WebBrowser category) - it does NOT automatically point at     ---
# --- Firefox just because Firefox is installed. Without this step,        ---
# --- clicking it can silently do nothing even with a working browser on   ---
# --- the system.                                                         ---

echo "Registering default browser for the desktop's Web Browser launcher..."
(
  set +e

  if command -v firefox >/dev/null 2>&1 && firefox --version >/dev/null 2>&1; then
    DEFAULT_BROWSER_BIN="/usr/bin/firefox"
    DEFAULT_BROWSER_NAME="firefox.desktop"
  elif command -v epiphany >/dev/null 2>&1; then
    DEFAULT_BROWSER_BIN="/usr/bin/epiphany"
    DEFAULT_BROWSER_NAME="org.gnome.Epiphany.desktop"
  else
    echo "  No working browser found to register as default."
    exit 0
  fi

  # System-level alternative (used by xdg-open / exo-open under the hood)
  sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser "$DEFAULT_BROWSER_BIN" 200 >/dev/null 2>&1
  sudo update-alternatives --set x-www-browser "$DEFAULT_BROWSER_BIN" >/dev/null 2>&1

  # XFCE-specific default-apps association (what the panel launcher reads)
  mkdir -p ~/.config/xfce4
  cat > ~/.config/xfce4/helpers.rc << HELPERS
WebBrowser=custom-WebBrowser
HELPERS
  mkdir -p ~/.local/share/xfce4/helpers
  cat > ~/.local/share/xfce4/helpers/custom-WebBrowser.desktop << CUSTOMHELPER
[Desktop Entry]
Version=1.0
Type=X-XFCE-Helper
X-XFCE-Category=WebBrowser
X-XFCE-CommandsWithParameter=$DEFAULT_BROWSER_BIN "%s"
X-XFCE-Commands=$DEFAULT_BROWSER_BIN
Icon=web-browser
Name=Default Browser
CUSTOMHELPER

  # freedesktop-level default too, in case anything reads it that way
  xdg-settings set default-web-browser "$DEFAULT_BROWSER_NAME" >/dev/null 2>&1

  echo "  Default browser registered: $DEFAULT_BROWSER_BIN"
  exit 0
)

# --- Protect downloads, browser logins/cookies, and saved passwords from   ---
# --- ever being lost, even in the (rare) case of a full container rebuild ---
# --- (as opposed to a normal stop/resume, which already preserves         ---
# --- everything on its own). We do this by moving the relevant folders    ---
# --- into /workspaces/ubuntu-cloud-desktop, which lives on Codespaces'    ---
# --- persistent workspace volume - the one location guaranteed to survive ---
# --- both stop/resume AND rebuilds - then symlinking the usual home-      ---
# --- directory paths back to it so nothing else has to change.            ---

echo "Setting up persistent storage for downloads and browser data..."
(
  set +e

  PERSIST_DIR="/workspaces/ubuntu-cloud-desktop/persistent-data"
  mkdir -p "$PERSIST_DIR/Downloads" "$PERSIST_DIR/mozilla" "$PERSIST_DIR/epiphany-config" "$PERSIST_DIR/epiphany-cache"

  link_to_persist() {
    local target="$1" persist="$2"
    if [ -L "$target" ]; then
      return 0  # already a symlink, nothing to do
    fi
    if [ -d "$target" ] && [ "$(ls -A "$target" 2>/dev/null)" ]; then
      # Real folder with existing data - migrate it in, don't lose it
      cp -a "$target"/. "$persist"/ 2>/dev/null
      rm -rf "$target"
    else
      rm -rf "$target"
    fi
    ln -sfn "$persist" "$target"
  }

  link_to_persist ~/Downloads "$PERSIST_DIR/Downloads"
  link_to_persist ~/.mozilla "$PERSIST_DIR/mozilla"
  mkdir -p ~/.config
  link_to_persist ~/.config/epiphany "$PERSIST_DIR/epiphany-config"
  mkdir -p ~/.cache
  link_to_persist ~/.cache/epiphany "$PERSIST_DIR/epiphany-cache"

  echo "  Downloads and browser profiles now persist in the repo's workspace folder."
  exit 0
)

echo "Setup complete."
