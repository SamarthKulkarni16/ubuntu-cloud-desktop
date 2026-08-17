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

echo "Installing real Firefox (not the Ubuntu snap redirect, which doesn't work in containers)..."
wget -q -O /tmp/firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
sudo tar xjf /tmp/firefox.tar.bz2 -C /opt/
sudo ln -sf /opt/firefox/firefox /usr/local/bin/firefox
rm -f /tmp/firefox.tar.bz2

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

echo "Setup complete."
