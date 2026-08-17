#!/usr/bin/env bash
set -e

# Safety check: if core setup never completed (e.g. setup.sh was
# interrupted or never ran), fail loudly with a clear fix instead of
# vncserver dying on a missing password file with a cryptic error.
if [ ! -f ~/.vnc/passwd ] || [ ! -f ~/.vnc/xstartup ]; then
  echo "ERROR: VNC is not configured yet (~/.vnc/passwd or ~/.vnc/xstartup missing)."
  echo "Run setup first: bash .devcontainer/setup.sh"
  exit 1
fi

# Kill any stale VNC server on display :1
vncserver -kill :1 >/dev/null 2>&1 || true

echo "Starting XFCE desktop on VNC display :1..."
vncserver :1 -geometry 1280x800 -depth 24 -localhost no

echo "Starting noVNC websocket proxy on port 6080..."
nohup websockify --web=/usr/share/novnc/ 6080 localhost:5901 > /tmp/novnc.log 2>&1 &

# Confirm it actually came up instead of assuming success.
sleep 2
if ! curl -s -o /dev/null http://localhost:6080/vnc.html; then
  echo "WARNING: noVNC doesn't seem to be responding on port 6080 yet."
  echo "Check /tmp/novnc.log for details:"
  tail -n 20 /tmp/novnc.log 2>/dev/null || true
else
  echo "Desktop ready. Open port 6080 to connect."
fi
