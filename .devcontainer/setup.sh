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
  curl

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
  fi

  exit 0
)
echo "Firefox step finished (see above for outcome)."

echo "Setup complete."
