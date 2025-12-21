# Flutter App Environment Variables Setup

## Required Variables

### API_BASE_URL (REQUIRED)
```env
API_BASE_URL=http://192.168.0.65:3001/api/v1
```

**Description:**
- This is the base URL for your NestJS backend API
- The Flutter app will append endpoint paths to this URL
- Must include the full path including `/api/v1` prefix

**Examples:**

**Development (localhost):**
```env
API_BASE_URL=http://localhost:3000/api/v1
```

**Local Network (same WiFi):**
```env
API_BASE_URL=http://192.168.0.65:3001/api/v1
```

**Production:**
```env
API_BASE_URL=https://api.yourdomain.com/api/v1
```

## Setup Instructions

1. **Create `.env` file:**
   ```bash
   cd boxgaming
   cp .env.example .env
   ```

2. **Update the API_BASE_URL:**
   - Open `.env` file
   - Set `API_BASE_URL` to match your backend server URL
   - Make sure it includes the `/api/v1` prefix

3. **For Mobile Testing:**
   - If testing on a physical device or emulator:
     - Use your computer's local IP address (not `localhost`)
     - Find your IP: 
       - Windows: `ipconfig` → IPv4 Address
       - Mac/Linux: `ifconfig` or `ip addr`
     - Example: `http://192.168.0.65:3001/api/v1`

4. **Verify Backend CORS:**
   - Make sure your backend `.env` has the Flutter app's origin in `CORS_ORIGIN`
   - For mobile apps, you might need to add your IP address
   - Example: `CORS_ORIGIN=http://192.168.0.65:3001,http://localhost:3000`

## Important Notes

- ✅ The `.env` file is already configured in `pubspec.yaml` assets
- ✅ The app loads `.env` automatically in `main.dart`
- ✅ Never commit `.env` file to version control (add to `.gitignore`)
- ✅ Use different URLs for development and production builds

## Troubleshooting

**Error: "Failed to connect to API"**
- Check that `API_BASE_URL` is correct
- Verify backend server is running
- Check network connectivity (for mobile devices)
- Ensure backend CORS allows your origin

**Error: "Connection refused"**
- Make sure backend is running on the specified port
- For mobile devices, use IP address instead of `localhost`
- Check firewall settings

**CORS errors:**
- Add your Flutter app's origin to backend `CORS_ORIGIN`
- For mobile apps, you may need to add the IP address

## Production Build

For production builds, you can:
1. Use different `.env` files (`.env.production`)
2. Or set environment variables during build
3. Make sure to use HTTPS in production

Example production `.env`:
```env
API_BASE_URL=https://api.yourdomain.com/api/v1
```

