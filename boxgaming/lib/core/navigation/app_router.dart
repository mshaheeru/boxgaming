import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
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

class AppRouter {
  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: RouteConstants.root,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        GoRoute(
          path: RouteConstants.root,
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
            return const LoginPage();
          },
        ),
        GoRoute(
          path: RouteConstants.login,
          builder: (context, state) => const LoginPage(),
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
      ],
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoggedIn = authState is AuthAuthenticated;
        final isGoingToAuth = state.matchedLocation == RouteConstants.login;

        if (!isLoggedIn && !isGoingToAuth) {
          return RouteConstants.login;
        }
        if (isLoggedIn && isGoingToAuth) {
          return RouteConstants.root;
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

