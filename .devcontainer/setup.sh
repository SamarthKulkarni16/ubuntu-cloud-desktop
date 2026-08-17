#!/usr/bin/env bash
set -e

echo "Updating package lists..."
sudo apt-get update -y

echo "Installing Firefox, file manager, and basic desktop utilities..."
sudo apt-get install -y \
  firefox \
  pcmanfm \
  xterm \
  gedit \
  unzip \
  wget \
  curl

echo "Setup complete. Open port 6080 in the Ports tab to reach your Ubuntu desktop."
