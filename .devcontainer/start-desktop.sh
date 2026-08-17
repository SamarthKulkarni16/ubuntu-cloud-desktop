#!/usr/bin/env bash
set -e

# Kill any stale VNC server on display :1
vncserver -kill :1 >/dev/null 2>&1 || true

echo "Starting XFCE desktop on VNC display :1..."
vncserver :1 -geometry 1280x800 -depth 24 -localhost no

echo "Starting noVNC websocket proxy on port 6080..."
nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 > /tmp/novnc.log 2>&1 &

echo "Desktop ready. Open port 6080 to connect."
