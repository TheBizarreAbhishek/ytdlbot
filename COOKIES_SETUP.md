# How to Set Up YouTube Cookies

YouTube sometimes requires cookies to download videos. Here's how to set it up:

## Method 1: Export Cookies from Browser (Recommended)

### Step 1: Install Browser Extension

1. Install a cookie export extension:
   - Chrome/Edge: [Get Cookies.txt LOCALLY](https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
   - Firefox: [cookies.txt](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/)

### Step 2: Export Cookies

1. Go to https://www.youtube.com
2. Make sure you're logged in
3. Click the extension icon
4. Click "Export" or "Export cookies"
5. Save the file as `youtube-cookies.txt`

### Step 3: Upload to VPS

```bash
# On your local machine, upload the cookies file to VPS
scp youtube-cookies.txt root@your_vps_ip:/root/dhongibaba/ytdlbot/

# Or create the file directly on VPS
nano ~/dhongibaba/ytdlbot/youtube-cookies.txt
# Paste the cookies content
```

## Method 2: Use PO Token (Alternative)

PO Token is another way to authenticate with YouTube. Get it from:
https://github.com/yt-dlp/yt-dlp/wiki/PO-Token-Guide

Then add to your `.env` file:
```env
POTOKEN=your_po_token_here
```

## Method 3: Use Browser Cookies on VPS (If Firefox is installed)

If you install Firefox on your VPS and log in:

1. Install Firefox:
```bash
apt install -y firefox
```

2. Run Firefox and log in to YouTube (requires X11 or VNC)

3. Add to `.env`:
```env
BROWSERS=firefox
```

## Quick Fix: Download Cookies File

The easiest way is to export cookies from your browser on your local computer and upload them to the VPS.

The bot will automatically use `youtube-cookies.txt` if it exists in the bot directory.

## Verify Cookies Are Working

After setting up cookies, test by downloading a YouTube video through the bot. If it works, cookies are set up correctly.

