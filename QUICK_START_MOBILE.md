# Quick Start Guide - Mobile Apps

Complete guide to run React Native apps on your phone using Expo.

## Prerequisites

1. **Node.js 18+** installed
2. **Expo CLI** (will be installed with npm)
3. **Expo Go app** on your phone:
   - [iOS App Store](https://apps.apple.com/app/expo-go/id982107779)
   - [Android Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)

## Step-by-Step Setup

### 1. Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.100`)

**Mac/Linux:**
```bash
ifconfig | grep "inet "
```
Look for your local network IP (usually `192.168.x.x`)

### 2. Update Backend CORS (One Time)

Update `docker-compose.dev.yml` to allow your IP:

```yaml
CORS_ORIGIN: "http://localhost:3000,http://localhost:3001,http://YOUR_IP:3000"
```

Then restart backend:
```bash
docker-compose -f docker-compose.dev.yml restart backend
```

### 3. Setup Customer App

```bash
# Navigate to customer app
cd mobile-customer

# Install dependencies
npm install

# Create .env file
echo "EXPO_PUBLIC_API_URL=http://YOUR_IP:3000/api/v1" > .env
# Replace YOUR_IP with your actual IP (e.g., 192.168.1.100)

# Start the app
npm start
```

### 4. Setup Owner App

```bash
# Navigate to owner app (in a new terminal)
cd mobile-owner

# Install dependencies
npm install

# Create .env file
echo "EXPO_PUBLIC_API_URL=http://YOUR_IP:3000/api/v1" > .env

# Start the app
npm start
```

### 5. Connect Your Phone

1. **Make sure your phone and computer are on the same WiFi network**

2. **Open Expo Go app** on your phone

3. **Scan the QR code** shown in terminal:
   - **iOS**: Use Camera app to scan
   - **Android**: Use Expo Go app's scanner

4. The app will load on your phone!

## Testing Connection

Before running the app, test if your phone can reach the backend:

1. **On your phone's browser**, visit:
   ```
   http://YOUR_IP:3000/api/v1/health
   ```

2. **Should see**: `{"status":"ok",...}`

3. **If it works**, the mobile app will connect too!

## Troubleshooting

### "Unable to connect to server"

- ✅ Check IP address in `.env` matches your computer's IP
- ✅ Verify backend is running: `docker-compose -f docker-compose.dev.yml ps`
- ✅ Test from phone browser: `http://YOUR_IP:3000/api/v1/health`
- ✅ Check firewall allows port 3000
- ✅ Ensure same WiFi network

### "Network request failed"

- ✅ Backend CORS might not include your IP - update docker-compose.dev.yml
- ✅ Restart backend after CORS change
- ✅ Check backend logs for errors

### Expo Go can't connect

- ✅ Try tunnel mode: `expo start --tunnel` (slower but works across networks)
- ✅ Clear cache: `expo start -c`
- ✅ Check Expo CLI version: `npx expo --version`

## UI Library: React Native Paper

Both apps use **React Native Paper** (Material Design 3) - similar to Mantine UI:

- **Buttons**: `Button` component with variants
- **Cards**: `Card` for content containers
- **Inputs**: `TextInput` with outlined mode
- **Navigation**: React Navigation with bottom tabs
- **Icons**: Material Community Icons
- **Theming**: Custom theme with primary color

## Features Implemented

### Customer App
- ✅ Phone OTP authentication
- ✅ Browse venues with search and filters
- ✅ View venue details and grounds
- ✅ Book time slots
- ✅ Payment flow (placeholder)
- ✅ View booking history
- ✅ Booking details with QR code

### Owner App
- ✅ Phone OTP authentication (owner role)
- ✅ Today's bookings dashboard
- ✅ Revenue summary
- ✅ QR code scanner for check-in
- ✅ Mark bookings as started/completed
- ✅ Large, easy-to-tap buttons

## Next Steps

1. **Test the apps** on your phone
2. **Create test data** (venues, bookings) via admin dashboard
3. **Test booking flow** end-to-end
4. **Customize UI** as needed

## Development Tips

- **Hot Reload**: Changes auto-reload on phone
- **Shake phone**: Opens Expo developer menu
- **Reload**: Press `r` in terminal
- **View logs**: Check terminal or Expo DevTools




