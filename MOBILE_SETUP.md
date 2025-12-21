# Mobile App Setup Guide

Complete guide to run the React Native apps on your mobile device.

## Prerequisites

1. **Node.js 18+** installed
2. **Expo CLI** installed globally:
   ```bash
   npm install -g expo-cli
   ```
3. **Expo Go app** on your phone:
   - [iOS App Store](https://apps.apple.com/app/expo-go/id982107779)
   - [Android Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)

## Step 1: Find Your Computer's IP Address

### Windows
```bash
ipconfig
```
Look for "IPv4 Address" under your active network adapter (usually `192.168.x.x` or `10.0.x.x`)

### Mac/Linux
```bash
ifconfig | grep "inet "
# Or
ip addr show | grep "inet "
```

## Step 2: Configure API URL

1. **Navigate to mobile app directory**:
   ```bash
   cd mobile-customer
   ```

2. **Create `.env` file**:
   ```bash
   # Copy example
   cp .env.example .env
   ```

3. **Edit `.env` file** and replace `YOUR_IP` with your computer's IP:
   ```env
   EXPO_PUBLIC_API_URL=http://192.168.1.100:3000/api/v1
   ```
   Replace `192.168.1.100` with your actual IP address.

## Step 3: Update Backend CORS (If Needed)

The backend CORS is configured for localhost. For mobile access, you may need to update it:

1. **Update `docker-compose.dev.yml`**:
   ```yaml
   CORS_ORIGIN: "http://localhost:3000,http://localhost:3001,http://YOUR_IP:3000"
   ```

2. **Or update backend `.env`**:
   ```env
   CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://YOUR_IP:3000
   ```

3. **Restart backend**:
   ```bash
   docker-compose -f docker-compose.dev.yml restart backend
   ```

## Step 4: Install Dependencies

```bash
cd mobile-customer
npm install
```

## Step 5: Start the App

```bash
npm start
```

This will:
1. Start the Expo development server
2. Show a QR code in the terminal
3. Open Expo DevTools in your browser

## Step 6: Connect Your Phone

### Option A: Scan QR Code (Easiest)

1. **Open Expo Go** on your phone
2. **Scan the QR code**:
   - **iOS**: Use the built-in Camera app
   - **Android**: Use the Expo Go app's scanner
3. The app will load on your phone

### Option B: Enter URL Manually

1. Open Expo Go app
2. Tap "Enter URL manually"
3. Enter the URL shown in terminal (e.g., `exp://192.168.1.100:8081`)

## Important Requirements

### ✅ Same WiFi Network
Your phone and computer **must be on the same WiFi network**.

### ✅ Backend Running
Make sure the backend is running:
```bash
docker-compose -f docker-compose.dev.yml ps backend
```

### ✅ Firewall
Allow connections on port 3000 (backend) and 8081 (Expo).

## Troubleshooting

### "Unable to connect to server"

1. **Check IP address** is correct in `.env`
2. **Verify backend is running**: `curl http://YOUR_IP:3000/api/v1/health`
3. **Check firewall** settings
4. **Ensure same WiFi** network

### "Network request failed"

1. **Test API from phone's browser**: `http://YOUR_IP:3000/api/v1/health`
2. **Check CORS** configuration
3. **Verify backend logs** for errors

### Expo Go can't connect

1. **Check Expo CLI version**: `expo --version`
2. **Clear Expo cache**: `expo start -c`
3. **Try tunnel mode**: `expo start --tunnel` (slower but works across networks)

## Testing the Connection

1. **From your phone's browser**, visit:
   ```
   http://YOUR_IP:3000/api/v1/health
   ```
   Should return: `{"status":"ok",...}`

2. **If this works**, the mobile app should connect too.

## Development Tips

- **Hot Reload**: Changes automatically reload on your phone
- **Shake phone**: Opens Expo developer menu
- **Reload**: Press `r` in terminal or shake phone → Reload
- **View logs**: Check terminal or Expo DevTools

## Building for Production

When ready to build standalone apps:

```bash
# Install EAS CLI
npm install -g eas-cli

# Login
eas login

# Configure
eas build:configure

# Build
eas build --platform android
eas build --platform ios
```

## Owner App Setup

The owner app setup is identical:

```bash
cd mobile-owner
# Follow same steps as customer app
```

Use a different port or run them separately.




