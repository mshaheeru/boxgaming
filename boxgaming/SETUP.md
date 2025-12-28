# BoxGaming Flutter App - Setup Guide

## Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.3.0 or higher
- Android Studio / VS Code with Flutter extensions
- Backend API running (see backend README)

## Quick Start

### 1. Install Dependencies

```bash
cd boxgaming
flutter pub get
```

### 2. Configure Environment

Create a `.env` file in the `boxgaming` directory:

```env
API_BASE_URL=http://192.168.0.61:3000/api/v1
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**Important**: Replace `192.168.0.61` with your computer's local IP address.

**Finding Your IP**:
- **Windows**: Run `ipconfig` and look for IPv4 Address
- **Mac/Linux**: Run `ifconfig | grep "inet "`

### 3. Generate Code

Run code generation for JSON serialization:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # App widget with providers
├── core/                        # Core functionality
│   ├── constants/              # API endpoints, app constants, routes
│   ├── error/                  # Exceptions and failures
│   ├── network/                # API client and interceptors
│   ├── storage/                 # Local and secure storage
│   ├── theme/                  # App theme and colors
│   ├── utils/                   # Validators, formatters, extensions
│   ├── di/                      # Dependency injection
│   └── navigation/              # App routing
├── features/                    # Feature modules
│   ├── auth/                   # Authentication (complete)
│   ├── venues/                 # Venues (placeholder)
│   ├── bookings/               # Bookings (placeholder)
│   ├── payments/               # Payments (placeholder)
│   └── owner/                   # Owner features (placeholder)
└── shared/                      # Shared widgets and utilities
```

## Features Implemented

✅ **Authentication**
- Phone OTP login
- OTP verification
- Auto-login on app restart
- Logout functionality

✅ **Core Infrastructure**
- Clean Architecture setup
- BLoC state management
- Dependency injection
- Network layer with interceptors
- Secure storage for tokens
- Error handling with Either pattern
- Role-based navigation

## Next Steps

1. Implement Venues feature
2. Implement Bookings feature
3. Implement Payments feature
4. Complete Owner dashboard
5. Add QR code scanning
6. Add maps integration
7. Write tests

## Troubleshooting

### Build Runner Errors
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### API Connection Issues
- Verify `.env` file exists and has correct API URL
- Check backend is running
- Ensure phone and computer are on same network
- For Android emulator, use `10.0.2.2` instead of `localhost`

### Missing Generated Files
- Run `flutter pub run build_runner build` after creating new models
- Ensure `@JsonSerializable()` annotations are correct

## Development

### Adding a New Feature

1. Create domain entities
2. Define repository interface
3. Create use cases
4. Implement data models
5. Implement data sources
6. Implement repository
7. Create BLoC (events, states, bloc)
8. Create UI pages
9. Register dependencies in `injection_container.dart`
10. Add routes in `app_router.dart`

See `flutter_app_guide.md` for complete documentation.



