# Ubuntu Cloud Desktop

A real Ubuntu desktop, running in a GitHub Codespace, streamed to your browser via noVNC.

## How to open it

1. Click **Code -> Codespaces -> Create codespace on main** on this repo
   (or use this direct link: https://github.com/codespaces/new?repo=SamarthKulkarni16/ubuntu-cloud-desktop&machine=basicLinux32gb)
2. Wait for the container to build (first time takes a few minutes — it's installing Firefox and desktop tools).
3. Go to the **Ports** tab at the bottom of the Codespace window.
4. Click the globe icon next to port **6080** to open the desktop in a new browser tab.
5. VNC password: `ubuntu`

## What you can do

- Open Firefox, a file manager (PCManFM), a text editor (gedit), and a terminal (xterm) — all from the desktop's right-click menu.
- Install anything else with `sudo apt install <package>` from the Codespace terminal — it'll show up on the desktop.

## Limits to know

- Free GitHub accounts get **120 core-hours/month** (~60 hours on the default 2-core machine). Stop the codespace when you're done to avoid burning the quota.
- No GPU acceleration and no audio output — fine for browsing, coding, file management; not for video/games.
- Stop a codespace: Code -> Codespaces -> click the `...` next to your running codespace -> Stop codespace.
- Delete when truly done to free up your 15GB storage quota.
