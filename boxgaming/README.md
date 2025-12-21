# BoxGaming - Indoor Games Booking System

Flutter mobile application built with Clean Architecture, BLoC pattern, and role-based access control.

## Features

- **Customer Features**: Browse venues, book slots, manage bookings, make payments
- **Owner Features**: Manage bookings, scan QR codes, track revenue, view dashboard
- **Role-Based Access**: Single app with dynamic UI based on user role

## Architecture

- **Clean Architecture** with Domain, Data, and Presentation layers
- **BLoC** for state management
- **Dependency Injection** with GetIt
- **Type-safe Navigation** with GoRouter

## Setup

1. Install Flutter SDK 3.24.0+
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure environment:
   - Update `.env` with your API URL
4. Generate code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/           # Core functionality (network, storage, DI, etc.)
├── features/       # Feature modules (auth, venues, bookings, etc.)
└── shared/         # Shared widgets and utilities
```

See `flutter_app_guide.md` for complete documentation.


