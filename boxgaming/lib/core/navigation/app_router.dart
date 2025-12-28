import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart' show AuthLoading, AuthAuthenticated;
import '../../features/auth/presentation/pages/login_page.dart';
import '../../shared/utils/role_helper.dart';
import '../constants/route_constants.dart';
import '../../features/venues/presentation/pages/venues_list_page.dart';
import '../../features/venues/presentation/pages/venue_detail_page.dart';
import '../../features/bookings/presentation/pages/my_bookings_page.dart';
import '../../features/bookings/presentation/pages/booking_detail_page.dart';
import '../../features/bookings/presentation/pages/booking_screen_page.dart';
import '../../features/payments/presentation/pages/payment_page.dart';
import '../../features/owner/presentation/pages/owner_dashboard_page.dart';
import '../../features/owner/presentation/pages/qr_scanner_page.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/admin/presentation/pages/assign_owners_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/owner_management_page.dart';

class AppRouter {
  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: RouteConstants.root,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        GoRoute(
          path: RouteConstants.root,
          builder: (context, state) {
            try {
              final authState = authBloc.state;
              if (authState is AuthAuthenticated) {
                final user = authState.user;
                print('🏠 Root route builder - User: ${user.id}, Requires password change: ${user.requiresPasswordChange}');
                if (RoleHelper.isAdmin(user)) {
                  return const AdminDashboardPage();
                } else if (RoleHelper.isOwner(user)) {
                  return const OwnerDashboardPage();
                } else {
                  return const VenuesListPage();
                }
              }
              return const LoginPage();
            } catch (e) {
              print('❌ Error in root route builder: $e');
              return const LoginPage();
            }
          },
        ),
        GoRoute(
          path: RouteConstants.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: RouteConstants.changePassword,
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: RouteConstants.venuesList,
          builder: (context, state) {
            // Ensure venues are loaded when navigating to this page
            return const VenuesListPage();
          },
        ),
        GoRoute(
          path: RouteConstants.venueDetail,
          builder: (context, state) {
            final venueId = state.uri.queryParameters['id'] ?? '';
            return VenueDetailPage(venueId: venueId);
          },
        ),
        GoRoute(
          path: RouteConstants.ownerDashboard,
          builder: (context, state) => const OwnerDashboardPage(),
        ),
        GoRoute(
          path: RouteConstants.qrScanner,
          builder: (context, state) => const QRScannerPage(),
        ),
        GoRoute(
          path: RouteConstants.myBookings,
          builder: (context, state) => const MyBookingsPage(),
        ),
        GoRoute(
          path: RouteConstants.bookingDetail,
          builder: (context, state) {
            final bookingId = state.uri.queryParameters['id'] ?? '';
            return BookingDetailPage(bookingId: bookingId);
          },
        ),
        GoRoute(
          path: RouteConstants.booking,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            final ground = args?['ground'];
            final venueName = args?['venueName'] as String? ?? '';
            if (ground == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid booking data')),
              );
            }
            return BookingScreenPage(
              ground: ground,
              venueName: venueName,
            );
          },
        ),
        GoRoute(
          path: RouteConstants.payment,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            final bookingId = args?['bookingId'] as String? ?? state.uri.queryParameters['bookingId'] ?? '';
            final amount = args?['amount'] as double? ?? double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0.0;
            return PaymentPage(bookingId: bookingId, amount: amount);
          },
        ),
        GoRoute(
          path: RouteConstants.adminDashboard,
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: RouteConstants.assignOwners,
          builder: (context, state) => const AssignOwnersPage(),
        ),
        GoRoute(
          path: RouteConstants.ownerManagement,
          builder: (context, state) => const OwnerManagementPage(),
        ),
      ],
      redirect: (context, state) {
        try {
          // Don't redirect if we're already on the change password page
          if (state.matchedLocation == RouteConstants.changePassword) {
            return null;
          }
          
          final authState = authBloc.state;
          final isLoggedIn = authState is AuthAuthenticated;
          final isGoingToAuth = state.matchedLocation == RouteConstants.login;

          // If not logged in and not going to auth pages, redirect to login
          if (!isLoggedIn && !isGoingToAuth) {
            return RouteConstants.login;
          }

          // If logged in, check if password change is required
          if (isLoggedIn) {
            final user = (authState as AuthAuthenticated).user;
            
            // If password change is required, redirect to change password page
            if (user.requiresPasswordChange) {
              print('🔒 Global redirect: User requires password change, redirecting to change password');
              return RouteConstants.changePassword;
            }
            
            // If logged in and going to auth page, redirect to root
            if (isGoingToAuth) {
              return RouteConstants.root;
            }
          }

          return null;
        } catch (e) {
          print('❌ Router redirect error: $e');
          // If there's an error, just return null to let the builder handle it
          return null;
        }
      },
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (state) {
        // Only refresh on non-loading states to avoid unnecessary rebuilds
        // Use Future.microtask to ensure state is stable before notifying
        if (!_disposed && state is! AuthLoading) {
          Future.microtask(() {
            if (!_disposed) {
              try {
                notifyListeners();
              } catch (e) {
                // Silently handle errors during notification
                print('GoRouterRefreshStream notify error: $e');
              }
            }
          });
        }
      },
      onError: (error) {
        // Silently handle stream errors to prevent crashes
        if (!_disposed) {
          print('GoRouterRefreshStream error: $error');
        }
      },
      cancelOnError: false, // Don't cancel subscription on error
    );
  }

  late final StreamSubscription _subscription;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    try {
      _subscription.cancel();
    } catch (e) {
      // Ignore errors during cancellation
    }
    super.dispose();
  }
}

