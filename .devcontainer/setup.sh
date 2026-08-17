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

echo "Installing real Firefox (not the Ubuntu snap redirect, which doesn't work in containers)..."
(
  set +e  # failures in this subshell must not kill the parent script

  FIREFOX_OK=0
  for attempt in 1 2 3; do
    echo "  Firefox download attempt $attempt..."
    rm -f /tmp/firefox.tar.bz2
    wget -q --tries=2 --timeout=30 -O /tmp/firefox.tar.bz2 \
      "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"

    # Validate: file must exist, be non-trivial size, and actually be a
    # bzip2 archive (catches HTML error pages / partial downloads / redirects
    # that "succeed" as far as wget is concerned but aren't real archives).
    if [ -s /tmp/firefox.tar.bz2 ] && file /tmp/firefox.tar.bz2 | grep -qi "bzip2"; then
      FIREFOX_OK=1
      break
    else
      echo "  Attempt $attempt produced an invalid file, retrying..."
      sleep 3
    fi
  done

  if [ "$FIREFOX_OK" -eq 1 ]; then
    if sudo tar xjf /tmp/firefox.tar.bz2 -C /opt/ && [ -f /opt/firefox/firefox ]; then
      sudo ln -sf /opt/firefox/firefox /usr/local/bin/firefox
      echo "  Firefox installed successfully."
    else
      echo "  WARNING: Firefox archive extracted but binary not found as expected. Skipping Firefox install."
    fi
  else
    echo "  WARNING: Firefox download failed after 3 attempts. Skipping Firefox install."
    echo "  You can retry later from inside the desktop terminal with:"
    echo "    wget -O /tmp/firefox.tar.bz2 \"https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US\" && sudo tar xjf /tmp/firefox.tar.bz2 -C /opt/ && sudo ln -sf /opt/firefox/firefox /usr/local/bin/firefox"
  fi

  rm -f /tmp/firefox.tar.bz2
  exit 0
)
echo "Firefox step finished (see above for outcome)."

echo "Setup complete."
