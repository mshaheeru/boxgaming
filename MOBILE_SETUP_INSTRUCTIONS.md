# Mobile App Setup Instructions

## Your IP Address: `192.168.0.61`

I've already updated the backend CORS to allow your IP. Now follow these steps:

## Step 1: Create .env Files

### Customer App
```bash
cd mobile-customer
echo EXPO_PUBLIC_API_URL=http://192.168.0.61:3000/api/v1 > .env
```

### Owner App
```bash
cd mobile-owner
echo EXPO_PUBLIC_API_URL=http://192.168.0.61:3000/api/v1 > .env
```

## Step 2: Install Dependencies

### Customer App
```bash
cd mobile-customer
npm install
```

### Owner App
```bash
cd mobile-owner
npm install
```

## Step 3: Test Backend Connection

**From your phone's browser**, visit:
```
http://192.168.0.61:3000/api/v1/health
```

Should return: `{"status":"ok",...}`

**If this works**, your mobile apps will connect!

## Step 4: Start the Apps

### Customer App
```bash
cd mobile-customer
npm start
```

### Owner App (in a new terminal)
```bash
cd mobile-owner
npm start
```

## Step 5: Connect Your Phone

1. **Install Expo Go** on your phone:
   - [iOS App Store](https://apps.apple.com/app/expo-go/id982107779)
   - [Android Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)

2. **Make sure your phone and computer are on the same WiFi network**

3. **Scan the QR code** shown in the terminal:
   - **iOS**: Use Camera app to scan
   - **Android**: Use Expo Go app's scanner

4. The app will load on your phone!

## Troubleshooting

### Can't connect from phone browser

1. **Check Windows Firewall**:
   - Allow port 3000 through Windows Firewall
   - Or temporarily disable firewall to test

2. **Verify backend is running**:
   ```bash
   docker-compose -f docker-compose.dev.yml ps backend
   ```

3. **Check backend logs**:
   ```bash
   docker-compose -f docker-compose.dev.yml logs backend
   ```

### "Network request failed" in app

1. **Verify .env file** has correct IP:
   ```bash
   cat mobile-customer/.env
   # Should show: EXPO_PUBLIC_API_URL=http://192.168.0.61:3000/api/v1
   ```

2. **Test from phone browser first** (see Step 3)

3. **Check CORS** - backend should allow `http://192.168.0.61:3000`

### Expo Go can't connect

1. **Try tunnel mode** (works across networks, but slower):
   ```bash
   npm start -- --tunnel
   ```

2. **Clear cache**:
   ```bash
   npm start -- -c
   ```

## Quick Commands

```bash
# Customer App
cd mobile-customer
npm install
echo EXPO_PUBLIC_API_URL=http://192.168.0.61:3000/api/v1 > .env
npm start

# Owner App (new terminal)
cd mobile-owner
npm install
echo EXPO_PUBLIC_API_URL=http://192.168.0.61:3000/api/v1 > .env
npm start
```

## Your Configuration

- **IP Address**: `192.168.0.61`
- **Backend URL**: `http://192.168.0.61:3000/api/v1`
- **Backend CORS**: ✅ Already configured
- **Admin Dashboard**: `http://localhost:3001` (or `http://192.168.0.61:3001`)

## Next Steps

1. Create `.env` files (see Step 1)
2. Install dependencies (see Step 2)
3. Test from phone browser (see Step 3)
4. Start the apps (see Step 4)
5. Scan QR codes with Expo Go

Good luck! 🚀




