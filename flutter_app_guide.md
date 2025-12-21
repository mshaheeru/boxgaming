# Complete Flutter Mobile App Guide - Indoor Games Booking System

This document contains **ALL** information needed to build a Flutter mobile app for the Indoor Games Booking System using Clean Architecture, BLoC pattern, and role-based access control.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Clean Architecture Layers](#clean-architecture-layers)
6. [BLoC State Management](#bloc-state-management)
7. [Role-Based Access Control](#role-based-access-control)
8. [Complete Setup Instructions](#complete-setup-instructions)
9. [Source Code - All Files](#source-code---all-files)
10. [API Integration](#api-integration)
11. [Features Implementation](#features-implementation)
12. [Testing Strategy](#testing-strategy)
13. [Build & Deployment](#build--deployment)

---

## Project Overview

A single Flutter mobile application with role-based access control that serves both:
- **Customers**: Browse venues, book slots, manage bookings, make payments
- **Owners**: Manage bookings, scan QR codes, track revenue, view dashboard

### Key Features
- Phone OTP authentication
- Role-based UI and navigation
- Venue browsing with search and filters
- Booking management
- QR code scanning (owner)
- Payment integration
- Real-time booking updates

---

## Architecture Overview

### Clean Architecture Principles

The app follows **Clean Architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (UI, BLoC, Widgets, Pages)                             │
│  - Depends on: Domain Layer                             │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                     Domain Layer                        │
│  (Entities, Use Cases, Repository Interfaces)           │
│  - Pure business logic, no dependencies                │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Data Layer                           │
│  (Repositories, Data Sources, Models, DTOs)            │
│  - Depends on: Domain Layer                             │
└─────────────────────────────────────────────────────────┘
```

### Dependency Rule
- **Inner layers** don't know about outer layers
- **Dependencies point inward** (Presentation → Domain ← Data)
- **Domain layer** is completely independent

---

## Tech Stack

### Core Framework
- **Flutter SDK**: 3.24.0+
- **Dart**: 3.3.0+
- **State Management**: flutter_bloc ^8.1.6
- **Dependency Injection**: get_it ^7.7.0
- **Navigation**: go_router ^14.0.0

### Networking & Storage
- **HTTP Client**: dio ^5.4.0
- **Local Storage**: shared_preferences ^2.2.2
- **Secure Storage**: flutter_secure_storage ^9.0.0

### UI & Design
- **Material Design**: Flutter Material 3
- **Icons**: flutter_svg ^2.0.9
- **Image Loading**: cached_network_image ^3.3.1
- **QR Code**: qr_flutter ^4.1.0
- **QR Scanner**: mobile_scanner ^5.2.3
- **Maps**: google_maps_flutter ^2.5.0
- **Location**: geolocator ^12.0.0

### Utilities
- **Date/Time**: intl ^0.19.0
- **JSON Serialization**: json_annotation ^4.8.1, json_serializable ^6.7.1
- **Logging**: logger ^2.0.2
- **Environment**: flutter_dotenv ^5.1.0

### Code Quality
- **Linting**: flutter_lints ^3.0.1
- **Code Generation**: build_runner ^2.4.7

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # App widget with providers
│
├── core/                              # Core functionality
│   ├── constants/
│   │   ├── api_constants.dart         # API endpoints
│   │   ├── app_constants.dart         # App-wide constants
│   │   └── route_constants.dart       # Route names
│   ├── error/
│   │   ├── exceptions.dart            # Custom exceptions
│   │   └── failures.dart              # Failure classes
│   ├── network/
│   │   ├── api_client.dart            # Dio client setup
│   │   ├── interceptors.dart          # Request/response interceptors
│   │   └── network_info.dart          # Network connectivity checker
│   ├── storage/
│   │   ├── local_storage.dart         # SharedPreferences wrapper
│   │   └── secure_storage.dart        # Secure storage wrapper
│   ├── theme/
│   │   ├── app_theme.dart             # Theme configuration
│   │   └── app_colors.dart            # Color constants
│   ├── utils/
│   │   ├── validators.dart            # Input validators
│   │   ├── date_formatters.dart       # Date formatting utilities
│   │   └── extensions.dart            # Dart extensions
│   └── di/
│       └── injection_container.dart   # Dependency injection setup
│
├── features/                          # Feature modules
│   ├── auth/                          # Authentication feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   └── auth_response_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── send_otp_usecase.dart
│   │   │       ├── verify_otp_usecase.dart
│   │   │       ├── get_current_user_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           ├── phone_input_page.dart
│   │           └── otp_verify_page.dart
│   │
│   ├── venues/                         # Venues feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── venues_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── venue_model.dart
│   │   │   │   └── ground_model.dart
│   │   │   └── repositories/
│   │   │       └── venues_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── venue_entity.dart
│   │   │   │   └── ground_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── venues_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_venues_usecase.dart
│   │   │       ├── get_venue_details_usecase.dart
│   │   │       └── search_venues_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── venues_bloc.dart
│   │       │   ├── venues_event.dart
│   │       │   └── venues_state.dart
│   │       └── pages/
│   │           ├── venues_list_page.dart
│   │           └── venue_detail_page.dart
│   │
│   ├── bookings/                       # Bookings feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── bookings_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── booking_model.dart
│   │   │   │   └── slot_model.dart
│   │   │   └── repositories/
│   │   │       └── bookings_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── booking_entity.dart
│   │   │   │   └── slot_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── bookings_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_available_slots_usecase.dart
│   │   │       ├── create_booking_usecase.dart
│   │   │       ├── get_my_bookings_usecase.dart
│   │   │       ├── get_booking_details_usecase.dart
│   │   │       └── cancel_booking_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── bookings_bloc.dart
│   │       │   ├── bookings_event.dart
│   │       │   └── bookings_state.dart
│   │       └── pages/
│   │           ├── booking_screen_page.dart
│   │           ├── my_bookings_page.dart
│   │           └── booking_detail_page.dart
│   │
│   ├── payments/                       # Payments feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── payments_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── payment_model.dart
│   │   │   └── repositories/
│   │   │       └── payments_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── payment_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── payments_repository.dart
│   │   │   └── usecases/
│   │   │       └── initiate_payment_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── payments_bloc.dart
│   │       │   ├── payments_event.dart
│   │       │   └── payments_state.dart
│   │       └── pages/
│   │           └── payment_page.dart
│   │
│   └── owner/                          # Owner-specific features
│       ├── data/
│       │   ├── datasources/
│       │   │   └── owner_remote_datasource.dart
│       │   ├── models/
│       │   │   └── dashboard_model.dart
│       │   └── repositories/
│       │       └── owner_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── dashboard_entity.dart
│       │   ├── repositories/
│       │   │   └── owner_repository.dart
│       │   └── usecases/
│       │       ├── get_today_bookings_usecase.dart
│       │       ├── mark_booking_started_usecase.dart
│       │       └── mark_booking_completed_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── owner_bloc.dart
│           │   ├── owner_event.dart
│           │   └── owner_state.dart
│           └── pages/
│               ├── owner_dashboard_page.dart
│               └── qr_scanner_page.dart
│
└── shared/                             # Shared widgets and utilities
    ├── widgets/
    │   ├── loading_widget.dart
    │   ├── error_widget.dart
    │   ├── empty_state_widget.dart
    │   └── custom_button.dart
    └── utils/
        └── role_helper.dart            # Role-based UI helpers
```

---

## Clean Architecture Layers

### 1. Domain Layer (Business Logic)

**Purpose**: Pure business logic, no dependencies on frameworks or external libraries.

**Components**:
- **Entities**: Core business objects (e.g., `UserEntity`, `VenueEntity`)
- **Use Cases**: Single-purpose business operations (e.g., `SendOtpUseCase`)
- **Repository Interfaces**: Contracts for data access

**Example Entity**:
```dart
// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String phone;
  final String? name;
  final UserRole role;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    required this.createdAt,
  });
}

enum UserRole {
  customer,
  owner,
  admin,
}
```

**Example Use Case**:
```dart
// lib/features/auth/domain/usecases/send_otp_usecase.dart
class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String phone) async {
    return await repository.sendOtp(phone);
  }
}
```

### 2. Data Layer (Data Access)

**Purpose**: Implement data sources and repository interfaces.

**Components**:
- **Models**: Data transfer objects (DTOs) with JSON serialization
- **Data Sources**: Remote (API) and Local (cache/storage)
- **Repository Implementations**: Concrete implementations of domain repositories

**Example Model**:
```dart
// lib/features/auth/data/models/user_model.dart
@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.phone,
    super.name,
    required super.role,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

### 3. Presentation Layer (UI)

**Purpose**: UI components and state management.

**Components**:
- **BLoC**: State management (Events, States, Bloc)
- **Pages**: Screen widgets
- **Widgets**: Reusable UI components

**Example BLoC**:
```dart
// lib/features/auth/presentation/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await sendOtpUseCase(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(OtpSentSuccessfully()),
    );
  }

  // ... other event handlers
}
```

---

## BLoC State Management

### BLoC Pattern Overview

**BLoC (Business Logic Component)** separates business logic from UI:

```
UI → Event → BLoC → State → UI
```

### Event-Driven Architecture

**Events**: User actions or system triggers
```dart
// Example: Auth Events
abstract class AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phone;
  SendOtpEvent(this.phone);
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  VerifyOtpEvent(this.phone, this.otp);
}
```

**States**: UI representation of data
```dart
// Example: Auth States
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);
}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
```

### BLoC Best Practices

1. **One BLoC per feature** (or sub-feature)
2. **Immutable states** (use `freezed` or `equatable`)
3. **Pure functions** in event handlers
4. **Error handling** with Either pattern
5. **Stream subscriptions** properly disposed

---

## Role-Based Access Control

### Role Detection

```dart
// lib/shared/utils/role_helper.dart
class RoleHelper {
  static bool isCustomer(UserEntity? user) {
    return user?.role == UserRole.customer;
  }

  static bool isOwner(UserEntity? user) {
    return user?.role == UserRole.owner || user?.role == UserRole.admin;
  }

  static bool isAdmin(UserEntity? user) {
    return user?.role == UserRole.admin;
  }
}
```

### Navigation Based on Role

```dart
// lib/core/navigation/app_router.dart
class AppRouter {
  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final authState = authBloc.state;
            if (authState is AuthAuthenticated) {
              final user = authState.user;
              if (RoleHelper.isOwner(user)) {
                return const OwnerDashboardPage();
              } else {
                return const VenuesListPage();
              }
            }
            return const PhoneInputPage();
          },
        ),
        // ... other routes
      ],
    );
  }
}
```

### UI Conditional Rendering

```dart
// Example: Show different UI based on role
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthAuthenticated) {
      final user = state.user;
      if (RoleHelper.isOwner(user)) {
        return OwnerBottomNavBar();
      } else {
        return CustomerBottomNavBar();
      }
    }
    return const SizedBox.shrink();
  },
)
```

---

## Complete Setup Instructions

### Prerequisites

- **Flutter SDK**: 3.24.0 or higher
- **Dart SDK**: 3.3.0 or higher
- **Android Studio** / **VS Code** with Flutter extensions
- **Backend API** running (see backend README)

### Step 1: Create Flutter Project

```bash
flutter create indoor_games_app
cd indoor_games_app
```

### Step 2: Update pubspec.yaml

```yaml
name: indoor_games_app
description: Indoor Games Booking System - Flutter App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.7.0
  injectable: ^2.3.2
  
  # Navigation
  go_router: ^14.0.0
  
  # Networking
  dio: ^5.4.0
  retrofit: ^4.0.3
  
  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.2.3
  google_maps_flutter: ^2.5.0
  geolocator: ^12.0.0
  
  # Utilities
  intl: ^0.19.0
  json_annotation: ^4.8.1
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  dartz: ^0.10.1  # Either pattern for error handling
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  injectable_generator: ^2.4.1
  retrofit_generator: ^8.0.6
  
  # Testing
  mockito: ^5.4.4
  bloc_test: ^9.1.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  
  assets:
    - .env
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
          weight: 700
```

### Step 3: Create Directory Structure

```bash
mkdir -p lib/core/{constants,error,network,storage,theme,utils,di}
mkdir -p lib/features/{auth,venues,bookings,payments,owner}/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages}}
mkdir -p lib/shared/{widgets,utils}
mkdir -p test/{features/{auth,venues,bookings},core}
```

### Step 4: Create Environment File

Create `.env` file in project root:
```env
API_BASE_URL=http://192.168.0.61:3000/api/v1
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

**Important**: Replace `192.168.0.61` with your backend IP address.

### Step 5: Install Dependencies

```bash
flutter pub get
```

### Step 6: Install Additional Dependencies

The guide uses `dartz` for Either pattern. Ensure it's in `pubspec.yaml`:

```yaml
dependencies:
  dartz: ^0.10.1  # For Either<Failure, Success> pattern
```

### Step 7: Generate Code

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Note**: You'll need to create the model files first before running build_runner. The generator will create `.g.dart` files for JSON serialization.

---

## Source Code - All Files

### Core Files

#### lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();
  runApp(const IndoorGamesApp());
}
```

#### lib/app.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class IndoorGamesApp extends StatelessWidget {
  const IndoorGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent())),
        // Add other BLoCs here
      ],
      child: MaterialApp.router(
        title: 'Indoor Games',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router(di.sl<AuthBloc>()),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

#### lib/core/constants/api_constants.dart
```dart
class ApiConstants {
  static String get baseUrl => _getBaseUrl();
  
  static String _getBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'http://localhost:3000/api/v1';
  }
  
  // Auth endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  
  // Venues endpoints
  static const String venues = '/venues';
  static String venueDetails(String id) => '/venues/$id';
  static String venueGrounds(String venueId) => '/venues/$venueId/grounds';
  
  // Bookings endpoints
  static String availableSlots(String groundId) => '/bookings/grounds/$groundId/slots';
  static const String bookings = '/bookings';
  static String myBookings = '/bookings/my-bookings';
  static String bookingDetails(String id) => '/bookings/$id';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String startBooking(String id) => '/bookings/$id/start';
  static String completeBooking(String id) => '/bookings/$id/complete';
  
  // Payments endpoints
  static String initiatePayment(String bookingId) => '/payments/initiate/$bookingId';
  
  // Users endpoints
  static const String currentUser = '/users/me';
}
```

#### lib/core/error/exceptions.dart
```dart
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
```

#### lib/core/error/failures.dart
```dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
```

#### lib/core/network/api_client.dart
```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'interceptors.dart';

class ApiClient {
  late Dio _dio;
  final SecureStorage _secureStorage;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseURL: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_secureStorage),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}
```

#### lib/core/storage/local_storage.dart
```dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _userKey = 'user_data';

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // Store user data as JSON string
    // Implementation depends on your needs
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve user data
    return null; // Implement based on your needs
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
```

#### lib/core/storage/secure_storage.dart
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
```

#### lib/core/network/interceptors.dart
```dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('Request: ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('Error: ${err.message}');
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized - clear token, redirect to login
    }
    handler.next(err);
  }
}
```

#### lib/core/di/injection_container.dart

**Important**: Update this file to include all features as you implement them. This is a complete example for Auth feature only.

**Complete Setup Example**:
```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/send_otp_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Core - Initialize storage first
  sl.registerLazySingleton(() => LocalStorage());
  sl.registerLazySingleton(() => SecureStorage());
  
  //! Core - Network
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiClient(sl()));

  //! Features - Auth
  // Bloc (Factory - new instance each time)
  sl.registerFactory(
    () => AuthBloc(
      sendOtpUseCase: sl(),
      verifyOtpUseCase: sl(),
      getCurrentUserUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use cases (LazySingleton - single instance)
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository (LazySingleton)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources (LazySingleton)
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl(),
      localStorage: sl(),
    ),
  );

  // TODO: Add other features (venues, bookings, payments, owner) here
}
```

**Dependency Order Matters**:
1. Core dependencies (storage, network) first
2. Data sources (they depend on core)
3. Repositories (they depend on data sources)
4. Use cases (they depend on repositories)
5. BLoCs (they depend on use cases)
```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/send_otp_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      sendOtpUseCase: sl(),
      verifyOtpUseCase: sl(),
      getCurrentUserUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  //! Core
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => LocalStorage());
  sl.registerLazySingleton(() => SecureStorage());
}
```

### Auth Feature - Complete Implementation

#### lib/features/auth/domain/entities/user_entity.dart
```dart
import 'package:equatable/equatable.dart';

enum UserRole {
  customer,
  owner,
  admin,
}

class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String? name;
  final UserRole role;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, phone, name, role, createdAt];
}
```

#### lib/features/auth/domain/repositories/auth_repository.dart
```dart
import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> sendOtp(String phone);
  Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp);
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, void>> logout();
}
```

#### lib/features/auth/domain/usecases/send_otp_usecase.dart
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String phone) async {
    return await repository.sendOtp(phone);
  }
}
```

#### lib/features/auth/domain/usecases/verify_otp_usecase.dart
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String phone, String otp) async {
    return await repository.verifyOtp(phone, otp);
  }
}
```

#### lib/features/auth/data/models/auth_response_model.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final String accessToken;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}
```

#### lib/features/auth/data/models/user_model.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.phone,
    super.name,
    required super.role,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      phone: phone,
      name: name,
      role: role,
      createdAt: createdAt,
    );
  }
}
```

#### lib/features/auth/data/datasources/auth_local_datasource.dart
```dart
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearToken();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage secureStorage;
  final LocalStorage localStorage;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
    required this.localStorage,
  });

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.getToken();
  }

  @override
  Future<void> saveUser(UserModel user) async {
    // Save user to local storage
    // Implementation depends on your storage strategy
  }

  @override
  Future<UserModel?> getUser() async {
    // Retrieve user from local storage
    return null; // Implement based on your needs
  }

  @override
  Future<void> clearToken() async {
    await secureStorage.clearToken();
  }

  @override
  Future<void> clearUser() async {
    await localStorage.clearUserData();
  }
}
```

#### lib/features/auth/data/datasources/auth_remote_datasource.dart
```dart
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String phone);
  Future<AuthResponseModel> verifyOtp(String phone, String otp);
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> sendOtp(String phone) async {
    try {
      await apiClient.dio.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  @override
  Future<AuthResponseModel> verifyOtp(String phone, String otp) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.verifyOtp,
        data: {'phone': phone, 'otp': otp},
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Invalid OTP');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.currentUser);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Failed to get user');
    }
  }
}
```

#### lib/features/auth/data/repositories/auth_repository_impl.dart
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> sendOtp(String phone) async {
    try {
      await remoteDataSource.sendOtp(phone);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp) async {
    try {
      final authResponse = await remoteDataSource.verifyOtp(phone, otp);
      await localDataSource.saveToken(authResponse.accessToken);
      await localDataSource.saveUser(authResponse.user);
      return Right(authResponse.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure('Failed to get current user'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to logout'));
    }
  }
}
```

#### lib/features/auth/presentation/bloc/auth_event.dart
```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SendOtpEvent extends AuthEvent {
  final String phone;
  const SendOtpEvent(this.phone);

  @override
  List<Object> get props => [phone];
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  const VerifyOtpEvent(this.phone, this.otp);

  @override
  List<Object> get props => [phone, otp];
}

class CheckAuthStatusEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}
```

#### lib/features/auth/presentation/bloc/auth_state.dart
```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSentSuccessfully extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
```

#### lib/features/auth/presentation/bloc/auth_bloc.dart
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onSendOtp(
    SendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await sendOtpUseCase(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(OtpSentSuccessfully()),
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await verifyOtpUseCase(event.phone, event.otp);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await getCurrentUserUseCase();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
```

#### lib/core/navigation/app_router.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/venues/presentation/pages/venues_list_page.dart';
import '../../features/owner/presentation/pages/owner_dashboard_page.dart';
import '../../shared/utils/role_helper.dart';

class AppRouter {
  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final authState = authBloc.state;
            if (authState is AuthAuthenticated) {
              final user = authState.user;
              if (RoleHelper.isOwner(user)) {
                return const OwnerDashboardPage();
              } else {
                return const VenuesListPage();
              }
            }
            return const PhoneInputPage();
          },
        ),
        GoRoute(
          path: '/phone-input',
          builder: (context, state) => const PhoneInputPage(),
        ),
        GoRoute(
          path: '/otp-verify',
          builder: (context, state) {
            final phone = state.uri.queryParameters['phone'] ?? '';
            return OtpVerifyPage(phone: phone);
          },
        ),
        // Add more routes as needed
      ],
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoggedIn = authState is AuthAuthenticated;
        final isGoingToAuth = state.matchedLocation == '/phone-input' ||
            state.matchedLocation == '/otp-verify';

        if (!isLoggedIn && !isGoingToAuth) {
          return '/phone-input';
        }
        if (isLoggedIn && isGoingToAuth) {
          return '/';
        }
        return null;
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

#### lib/core/utils/validators.dart
```dart
class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Basic phone validation - adjust regex as needed
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }
}
```

#### lib/core/theme/app_theme.dart
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EE),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
```

#### lib/features/auth/presentation/pages/otp_verify_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/utils/validators.dart';

class OtpVerifyPage extends StatefulWidget {
  final String phone;
  const OtpVerifyPage({super.key, required this.phone});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerifyOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            VerifyOtpEvent(widget.phone, _otpController.text),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Navigation handled by router
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter the 6-digit code sent to ${widget.phone}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                      hintText: '123456',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateOtp,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is AuthLoading ? null : _handleVerifyOtp,
                      child: state is AuthLoading
                          ? const CircularProgressIndicator()
                          : const Text('Verify OTP'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Change Phone Number'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

#### lib/features/auth/presentation/pages/phone_input_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/utils/validators.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(SendOtpEvent(_phoneController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Indoor Games'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpSentSuccessfully) {
            Navigator.pushNamed(
              context,
              '/otp-verify',
              arguments: _phoneController.text,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Enter your phone number',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+923001234567',
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is AuthLoading ? null : _handleSendOtp,
                      child: state is AuthLoading
                          ? const CircularProgressIndicator()
                          : const Text('Send OTP'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## API Integration

### API Endpoints Summary

#### Authentication
- `POST /auth/send-otp` - Send OTP to phone
- `POST /auth/verify-otp` - Verify OTP and get token
- `GET /users/me` - Get current user

#### Venues
- `GET /venues` - List venues (with filters)
- `GET /venues/:id` - Get venue details
- `GET /venues/:venueId/grounds` - Get venue grounds

#### Bookings
- `GET /bookings/grounds/:groundId/slots` - Get available slots
- `POST /bookings` - Create booking
- `GET /bookings/my-bookings` - Get user bookings
- `GET /bookings/:id` - Get booking details
- `POST /bookings/:id/cancel` - Cancel booking
- `POST /bookings/:id/start` - Mark started (owner)
- `POST /bookings/:id/complete` - Mark completed (owner)

#### Payments
- `POST /payments/initiate/:bookingId` - Initiate payment

### Error Handling

All API calls use Either pattern:
- **Left**: Failure (error)
- **Right**: Success (data)

```dart
// Example usage
final result = await getVenuesUseCase();
result.fold(
  (failure) => // Handle error
  (venues) => // Handle success
);
```

---

## Features Implementation

### Customer Features

1. **Authentication**
   - Phone number input
   - OTP verification
   - Auto-login on app restart

2. **Venue Browsing**
   - List all venues
   - Search by name
   - Filter by sport type
   - View venue details
   - View grounds and pricing

3. **Booking Management**
   - Select date and time slot
   - Choose duration (2hr/3hr)
   - Create booking
   - View booking history
   - Cancel bookings
   - View booking QR code

4. **Payments**
   - Select payment method
   - Initiate payment
   - Payment confirmation

### Owner Features

1. **Dashboard**
   - Today's bookings list
   - Revenue summary
   - Booking statistics

2. **QR Scanner**
   - Scan booking QR codes
   - Verify bookings
   - Mark bookings as started/completed

3. **Booking Management**
   - View all bookings
   - Filter by status
   - Update booking status

---

## Testing Strategy

### Unit Tests

Test each layer independently:

**Setup test dependencies** (`test/helpers/test_helpers.dart`):
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import '../../lib/features/auth/domain/repositories/auth_repository.dart';
import '../../lib/features/auth/domain/entities/user_entity.dart';
import '../../lib/core/error/failures.dart';

@GenerateMocks([AuthRepository])
void main() {}
```

**Use case test** (`test/features/auth/domain/usecases/send_otp_usecase_test.dart`):
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:indoorgames_app/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:indoorgames_app/core/error/failures.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late SendOtpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendOtpUseCase(mockRepository);
  });

  test('should send OTP successfully', () async {
    // Arrange
    when(mockRepository.sendOtp(any))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase('+923001234567');

    // Assert
    expect(result, const Right(null));
    verify(mockRepository.sendOtp('+923001234567'));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    when(mockRepository.sendOtp(any))
        .thenAnswer((_) async => const Left(ServerFailure('Server error')));

    // Act
    final result = await useCase('+923001234567');

    // Assert
    expect(result, const Left(ServerFailure('Server error')));
  });
}
```

**Generate mocks**:
```bash
flutter pub run build_runner build
```

### Widget Tests

Test UI components:

```dart
void main() {
  testWidgets('PhoneInputPage displays correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => MockAuthBloc(),
          child: const PhoneInputPage(),
        ),
      ),
    );

    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
```

### BLoC Tests

Test state management using `bloc_test` package:

**BLoC test** (`test/features/auth/presentation/bloc/auth_bloc_test.dart`):
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:indoorgames_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:indoorgames_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:indoorgames_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:indoorgames_app/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:indoorgames_app/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:indoorgames_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:indoorgames_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:indoorgames_app/core/error/failures.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late AuthBloc bloc;
  late MockSendOtpUseCase mockSendOtpUseCase;
  late MockVerifyOtpUseCase mockVerifyOtpUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockLogoutUseCase mockLogoutUseCase;

  setUp(() {
    mockSendOtpUseCase = MockSendOtpUseCase();
    mockVerifyOtpUseCase = MockVerifyOtpUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    
    bloc = AuthBloc(
      sendOtpUseCase: mockSendOtpUseCase,
      verifyOtpUseCase: mockVerifyOtpUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      logoutUseCase: mockLogoutUseCase,
    );
  });

  test('initial state is AuthInitial', () {
    expect(bloc.state, equals(AuthInitial()));
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, OtpSentSuccessfully] when SendOtpEvent succeeds',
    build: () {
      when(mockSendOtpUseCase(any))
          .thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) => bloc.add(SendOtpEvent('+923001234567')),
    expect: () => [
      AuthLoading(),
      OtpSentSuccessfully(),
    ],
    verify: (_) {
      verify(mockSendOtpUseCase('+923001234567')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when SendOtpEvent fails',
    build: () {
      when(mockSendOtpUseCase(any))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));
      return bloc;
    },
    act: (bloc) => bloc.add(SendOtpEvent('+923001234567')),
    expect: () => [
      AuthLoading(),
      AuthError('Server error'),
    ],
  );
}
```

---

## Build & Deployment

### Android Build

1. **Configure signing**:
   - Create `android/key.properties`
   - Update `android/app/build.gradle`

2. **Build APK**:
   ```bash
   flutter build apk --release
   ```

3. **Build App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

### iOS Build

1. **Configure signing**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Configure signing & capabilities

2. **Build IPA**:
   ```bash
   flutter build ipa --release
   ```

### Environment Configuration

For production, update `.env`:
```env
API_BASE_URL=https://api.indoorgames.com/api/v1
GOOGLE_MAPS_API_KEY=production_key
```

---

## Clean Code Principles Applied

### 1. **Single Responsibility Principle (SRP)**
- Each class has one reason to change
- Use cases handle single operations
- BLoCs manage single feature state

### 2. **Open/Closed Principle**
- Entities are open for extension, closed for modification
- Use interfaces for repositories
- Extend functionality through inheritance and composition

### 3. **Dependency Inversion Principle**
- Depend on abstractions (interfaces), not concretions
- Dependency injection via GetIt

### 4. **DRY (Don't Repeat Yourself)**
- Shared widgets for common UI
- Base classes for common functionality
- Utility functions for repeated logic

### 5. **SOLID Principles**
- All SOLID principles followed throughout architecture
- Clean separation of concerns

### 6. **Naming Conventions**
- Clear, descriptive names
- Consistent naming patterns
- Self-documenting code

### 7. **Error Handling**
- Consistent error handling with Either pattern
- Proper exception mapping
- User-friendly error messages

---

## How to Read This Project

### For New Developers

1. **Start with `main.dart`** - Entry point
2. **Check `app.dart`** - App configuration and providers
3. **Review `injection_container.dart`** - Understand dependencies
4. **Explore a feature** (e.g., `auth`) - See complete flow:
   - Domain → Entities, Use Cases
   - Data → Models, Data Sources, Repository Implementation
   - Presentation → BLoC, Pages
5. **Follow data flow**:
   ```
   UI → Event → BLoC → Use Case → Repository → Data Source → API
   API → Data Source → Repository → Use Case → BLoC → State → UI
   ```

### Architecture Flow

```
User Action
    ↓
Page Widget (UI)
    ↓
BLoC Event
    ↓
BLoC Handler
    ↓
Use Case
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
Data Source (Remote/Local)
    ↓
API/Storage
    ↓
Response flows back up
    ↓
BLoC State
    ↓
UI Update
```

### Key Files to Understand

1. **Core Layer**:
   - `core/di/injection_container.dart` - Dependency setup
   - `core/network/api_client.dart` - HTTP client
   - `core/error/failures.dart` - Error handling

2. **Feature Example (Auth)**:
   - `domain/entities/user_entity.dart` - Business model
   - `domain/usecases/verify_otp_usecase.dart` - Business logic
   - `data/models/user_model.dart` - Data model
   - `presentation/bloc/auth_bloc.dart` - State management
   - `presentation/pages/phone_input_page.dart` - UI

3. **Navigation**:
   - `core/navigation/app_router.dart` - Route configuration

---

## Important Notes

1. **Environment Variables**: Always use `.env` file, never hardcode URLs
2. **Error Handling**: Always use Either pattern, never throw exceptions in use cases
3. **State Management**: One BLoC per feature, keep states immutable
4. **Testing**: Write tests for use cases, BLoCs, and critical widgets
5. **Code Generation**: Run `build_runner` after adding new models
6. **Dependencies**: Use `get_it` for dependency injection
7. **Navigation**: Use `go_router` for type-safe navigation
8. **Role-Based Access**: Check user role before showing UI or allowing actions

---

## Additional Implementation Files

### lib/shared/utils/role_helper.dart
```dart
import '../../features/auth/domain/entities/user_entity.dart';

class RoleHelper {
  static bool isCustomer(UserEntity? user) {
    return user?.role == UserRole.customer;
  }

  static bool isOwner(UserEntity? user) {
    return user?.role == UserRole.owner || user?.role == UserRole.admin;
  }

  static bool isAdmin(UserEntity? user) {
    return user?.role == UserRole.admin;
  }

  static bool canAccessOwnerFeatures(UserEntity? user) {
    return isOwner(user);
  }
}
```

### lib/shared/widgets/loading_widget.dart
```dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
```

### lib/shared/widgets/error_widget.dart
```dart
import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Troubleshooting

### Common Issues

1. **Build Runner Errors**:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Dependency Injection Errors**:
   - Ensure all dependencies are registered in `injection_container.dart`
   - Check import paths
   - Verify `dartz` package is added for Either pattern

3. **API Connection Issues**:
   - Verify `.env` file exists and has correct API URL
   - Check backend is running
   - Ensure phone and computer are on same network
   - For Android emulator, use `10.0.2.2` instead of `localhost`

4. **BLoC State Not Updating**:
   - Check event is being dispatched
   - Verify BLoC is provided in widget tree
   - Check state equality (use Equatable)
   - Ensure BLoC is listening to the correct stream

5. **Code Generation Issues**:
   - Run `flutter pub get` first
   - Delete `.dart_tool` folder if needed
   - Ensure all `@JsonSerializable()` annotations are correct

---

## Next Steps

After setting up the project:

1. Implement remaining features (venues, bookings, payments)
2. Add error handling and loading states
3. Implement offline support (local caching)
4. Add push notifications
5. Write comprehensive tests
6. Optimize performance
7. Add analytics
8. Prepare for production deployment

---

## Quick Reference

### File Naming Conventions

- **Entities**: `*_entity.dart` (Domain layer)
- **Models**: `*_model.dart` (Data layer)
- **Use Cases**: `*_usecase.dart` (Domain layer)
- **Repositories**: `*_repository.dart` (Domain), `*_repository_impl.dart` (Data)
- **Data Sources**: `*_remote_datasource.dart`, `*_local_datasource.dart`
- **BLoCs**: `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- **Pages**: `*_page.dart`
- **Widgets**: `*_widget.dart`

### Import Order

1. Flutter packages
2. Third-party packages
3. Core (internal)
4. Features (internal)
5. Shared (internal)

Example:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../shared/widgets/loading_widget.dart';
```

### Code Organization Checklist

When implementing a new feature:

- [ ] Create domain entities
- [ ] Define repository interface
- [ ] Create use cases
- [ ] Implement data models
- [ ] Implement data sources (remote & local)
- [ ] Implement repository
- [ ] Create BLoC (events, states, bloc)
- [ ] Create UI pages
- [ ] Register dependencies in `injection_container.dart`
- [ ] Add routes in `app_router.dart`
- [ ] Write unit tests
- [ ] Write BLoC tests
- [ ] Write widget tests

### Common Patterns

**Either Pattern** (Error Handling):
```dart
Future<Either<Failure, T>> someOperation() async {
  try {
    final result = await dataSource.getData();
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

**BLoC Pattern** (State Management):
```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final UseCase useCase;
  
  FeatureBloc({required this.useCase}) : super(FeatureInitial()) {
    on<LoadFeatureEvent>(_onLoadFeature);
  }
  
  Future<void> _onLoadFeature(
    LoadFeatureEvent event,
    Emitter<FeatureState> emit,
  ) async {
    emit(FeatureLoading());
    final result = await useCase();
    result.fold(
      (failure) => emit(FeatureError(failure.message)),
      (data) => emit(FeatureLoaded(data)),
    );
  }
}
```

**Repository Pattern**:
```dart
abstract class FeatureRepository {
  Future<Either<Failure, Data>> getData();
}

class FeatureRepositoryImpl implements FeatureRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;
  
  @override
  Future<Either<Failure, Data>> getData() async {
    try {
      final data = await remoteDataSource.getData();
      await localDataSource.cacheData(data);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

---

## Summary

This guide provides:

✅ **Complete Clean Architecture** implementation
✅ **BLoC state management** pattern
✅ **Role-based access control** (single app for both customer and owner)
✅ **Comprehensive code examples** for all layers
✅ **Testing strategies** (unit, widget, BLoC tests)
✅ **Build and deployment** instructions
✅ **Clean code principles** applied throughout
✅ **Complete project structure** with all necessary files
✅ **Dependency injection** setup
✅ **Navigation** with role-based routing
✅ **Error handling** with Either pattern
✅ **API integration** examples

---

**End of Flutter App Guide**

This guide provides everything needed to build a production-ready Flutter app with Clean Architecture, BLoC pattern, and role-based access control. Follow the structure, implement features layer by layer, and maintain clean code principles throughout development.

