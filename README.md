# Ubuntu Cloud Desktop (XFCE)

A real Ubuntu desktop with a full XFCE environment — taskbar, app menu, file manager,
wallpaper — running in a GitHub Codespace and streamed to your browser via noVNC.

## How to open it

1. Click **Code -> Codespaces -> Create codespace on main** on this repo
   (or use this direct link: https://github.com/codespaces/new?repo=SamarthKulkarni16/ubuntu-cloud-desktop&machine=basicLinux32gb)
2. Wait for the container to build (first time takes 3-5 minutes — it's installing XFCE, a VNC server, and Firefox).
3. Go to the **Ports** tab at the bottom of the Codespace window.
4. Click the globe icon next to port **6080** to open the desktop in a new browser tab.
5. You should land straight on an XFCE desktop with a taskbar at the bottom and an applications menu button.

If the desktop doesn't appear or the tab is blank, open a terminal in the Codespace and run:
```
bash .devcontainer/start-desktop.sh
```
then reload the port-6080 browser tab.

## What you can do

- Full XFCE desktop: taskbar, app launcher menu, file manager (Thunar), Firefox, text editor.
- Install anything else with `sudo apt install <package>` from the Codespace terminal.
- Fullscreen the noVNC tab (there's a button in the side drawer / toolbar) for the closest feel to a real monitor.

## Limits to know

- Free GitHub accounts get **120 core-hours/month** (~60 hours on the default 2-core machine).
  Stop the codespace when you're done to avoid burning the quota.
- No GPU acceleration and no audio output — fine for browsing, coding, file management; not for video/games.
- Stop a codespace: Code -> Codespaces -> click the `...` next to your running codespace -> Stop codespace.
- Delete when truly done to free up your 15GB storage quota.
- Every time you *resume* a stopped codespace, `start-desktop.sh` re-launches the VNC server automatically —
  give it 10-20 seconds after resuming before opening the port-6080 tab.
