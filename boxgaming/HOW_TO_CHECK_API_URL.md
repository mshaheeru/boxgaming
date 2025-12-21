# How to Check Flutter App API URL

## Important Note
**Flutter apps don't run on a port** - they're mobile applications, not web servers. However, they **make HTTP requests** to your backend API, and you can check which API URL they're using.

## Method 1: Check App Startup Logs (Easiest)

When you start your Flutter app, look for these log messages in your terminal/console:

```
✅ Using API_BASE_URL from .env: http://192.168.0.79:3001/api/v1
🔗 API Base URL: http://192.168.0.79:3001/api/v1
```

**Where to find:**
- In your terminal where you ran `flutter run`
- In Android Studio's Logcat (if using Android Studio)
- In VS Code's Debug Console

## Method 2: Check Request Logs

When the app makes an API request, you'll see logs like:

```
Request: POST /auth/send-otp
Full URL: http://192.168.0.79:3001/api/v1/auth/send-otp
```

**Look for:**
- `Request: METHOD /path` - Shows the endpoint
- `Full URL: http://...` - Shows the complete URL being used

## Method 3: Check Error Logs

If there's a connection error, you'll see:

```
Error: DioExceptionType.connectionError
Full URL: http://192.168.0.79:3001/api/v1/auth/send-otp
Base URL: http://192.168.0.79:3001/api/v1
Cannot reach server at: http://192.168.0.79:3001/api/v1/auth/send-otp
```

## Method 4: Check Your .env File

The API URL is configured in `boxgaming/.env`:

```env
API_BASE_URL=http://192.168.0.79:3001/api/v1
```

**To view it:**
```bash
cd boxgaming
type .env    # Windows
cat .env     # Mac/Linux
```

## Method 5: Programmatically Check (For Debugging)

You can temporarily add this to any screen to display the API URL:

```dart
import 'package:boxgaming/core/constants/api_constants.dart';

// In your widget:
Text('API URL: ${ApiConstants.baseUrl}')
```

## Understanding the URL Structure

```
http://192.168.0.79:3001/api/v1
│    │              │    │   │
│    │              │    │   └─ API version
│    │              │    └───── API prefix
│    │              └────────── Backend port
│    └────────────────────────── Your computer's IP
└────────────────────────────── Protocol (HTTP)
```

**Full request example:**
- Base URL: `http://192.168.0.79:3001/api/v1`
- Endpoint: `/auth/send-otp`
- **Full URL:** `http://192.168.0.79:3001/api/v1/auth/send-otp`

## Quick Checklist

- [ ] Check startup logs for `🔗 API Base URL: ...`
- [ ] Check request logs for `Full URL: ...`
- [ ] Verify `.env` file has correct `API_BASE_URL`
- [ ] Make sure the URL matches your backend server address

## Common Issues

### If you see `localhost:3000`:
- Your `.env` file is missing or not loaded
- The app is using the fallback URL
- **Fix:** Create/update `.env` file with correct IP

### If you see wrong IP:
- Your `.env` file has the wrong IP
- **Fix:** Update `.env` with correct IP address

### If you see `10.0.2.2`:
- You're using Android Emulator (this is correct!)
- `10.0.2.2` is the emulator's way to access your computer's localhost

## Backend vs Flutter App

| Component | Port/URL | Purpose |
|-----------|----------|---------|
| **Backend API** | `http://192.168.0.79:3001` | Server that handles requests |
| **Flutter App** | N/A (mobile app) | Makes HTTP requests to backend |
| **API Endpoint** | `/api/v1/auth/send-otp` | Specific API route |

The Flutter app **connects to** the backend, it doesn't **run on** a port.

