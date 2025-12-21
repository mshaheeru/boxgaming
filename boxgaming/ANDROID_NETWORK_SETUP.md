# Android Network Setup Guide

## Problem
The Flutter app cannot connect to your backend server even though the server works fine in the browser.

## Solution

### 1. Network Security Configuration ✅ (Already Fixed)
I've added the network security config to allow HTTP traffic. This is required for Android 9+.

### 2. Choose the Correct IP Address

#### If using Android Emulator:
Android emulators use a special IP to access your host machine:
- Use: `http://10.0.2.2:3001/api/v1`
- This is a special IP that the emulator uses to access `localhost` on your computer

**Update your `.env` file:**
```env
API_BASE_URL=http://10.0.2.2:3001/api/v1
```

#### If using Physical Android Device:
1. Make sure your phone and computer are on the **same WiFi network**
2. Use your computer's actual IP address (e.g., `192.168.0.79`)
3. Make sure Windows Firewall allows connections on port 3001

**Update your `.env` file:**
```env
API_BASE_URL=http://192.168.0.79:3001/api/v1
```

### 3. Windows Firewall (For Physical Devices)

If using a physical device, you may need to allow the connection in Windows Firewall:

1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Click "Change Settings" → "Allow another app"
4. Add Node.js or allow port 3001

Or run this in PowerShell (as Administrator):
```powershell
New-NetFirewallRule -DisplayName "Node.js Backend" -Direction Inbound -LocalPort 3001 -Protocol TCP -Action Allow
```

### 4. Verify Your Setup

After updating `.env`, restart your Flutter app completely:
```bash
# Stop the app
# Then run:
flutter clean
flutter pub get
flutter run
```

Check the console logs - you should see:
```
✅ Using API_BASE_URL from .env: http://...
🔗 API Base URL: http://...
```

### 5. Test Connection

Try sending OTP again. If it still doesn't work:

1. **Check if you're using emulator or physical device:**
   - Emulator → Use `10.0.2.2`
   - Physical device → Use your computer's IP (`192.168.0.79`)

2. **Verify server is accessible:**
   - From your laptop browser: `http://192.168.0.79:3001/api/docs` ✅ (you said this works)
   - From your phone browser (if physical device): Try opening `http://192.168.0.79:3001/api/docs`

3. **Check backend logs:**
   - When you tap "Send OTP", do you see any request in backend logs?
   - If no request appears, the connection is being blocked

## Quick Checklist

- [ ] Network security config created ✅
- [ ] AndroidManifest.xml updated ✅
- [ ] `.env` file has correct IP:
  - [ ] Emulator: `http://10.0.2.2:3001/api/v1`
  - [ ] Physical device: `http://192.168.0.79:3001/api/v1`
- [ ] Flutter app restarted after `.env` change
- [ ] Windows Firewall allows port 3001 (physical device only)
- [ ] Phone and computer on same WiFi (physical device only)

