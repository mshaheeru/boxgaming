import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/venues/presentation/bloc/venues_bloc.dart';
import 'features/bookings/presentation/bloc/bookings_bloc.dart';
import 'features/payments/presentation/bloc/payments_bloc.dart';
import 'features/owner/presentation/bloc/owner_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';

class BoxGamingApp extends StatelessWidget {
  const BoxGamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a single AuthBloc instance to use in both provider and router
    final authBloc = di.sl<AuthBloc>()..add(CheckAuthStatusEvent());
    
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(create: (_) => di.sl<VenuesBloc>()),
        BlocProvider(create: (_) => di.sl<BookingsBloc>()),
        BlocProvider(create: (_) => di.sl<PaymentsBloc>()),
        // OwnerBloc and AdminBloc are created lazily in their respective pages
        // This prevents errors when they're closed during logout/login cycles
      ],
      child: MaterialApp.router(
        title: 'BoxGaming',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router(authBloc),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

