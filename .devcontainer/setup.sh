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
  firefox \
  gedit \
  unzip \
  wget \
  curl

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
