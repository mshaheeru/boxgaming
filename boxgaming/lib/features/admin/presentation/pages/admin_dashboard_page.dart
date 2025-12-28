import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color neonRed = const Color(0xFFFF1744);
    final Color darkBackground = const Color(0xFF0A0A0A);
    final Color darkSurface = const Color(0xFF1A1A1A);
    final Color darkCard = const Color(0xFF2A2A2A);

    return BlocProvider(
      create: (context) {
        try {
          return di.sl<AdminBloc>()..add(LoadAdminDashboardEvent());
        } catch (e) {
          print('❌ Error creating AdminBloc: $e');
          rethrow;
        }
      },
      child: Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          title: Text(
            'ADMIN DASHBOARD',
            style: GoogleFonts.audiowide(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: darkSurface,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: const AppDrawer(),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return Center(
                child: CircularProgressIndicator(color: neonRed),
              );
            }

            if (state is AdminError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: neonRed, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: GoogleFonts.saira(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AdminBloc>().add(LoadAdminDashboardEvent());
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: neonRed),
                      child: Text('RETRY', style: GoogleFonts.audiowide()),
                    ),
                  ],
                ),
              );
            }

            if (state is AdminDashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Tenants',
                            value: state.totalTenants.toString(),
                            icon: Icons.business,
                            color: Colors.blue,
                            neonRed: neonRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Owners',
                            value: state.totalOwners.toString(),
                            icon: Icons.people,
                            color: Colors.green,
                            neonRed: neonRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Active Venues',
                            value: state.activeVenues.toString(),
                            icon: Icons.location_on,
                            color: Colors.orange,
                            neonRed: neonRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Bookings',
                            value: state.totalBookings.toString(),
                            icon: Icons.calendar_today,
                            color: Colors.purple,
                            neonRed: neonRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Quick Actions
                    Text(
                      'QUICK ACTIONS',
                      style: GoogleFonts.audiowide(
                        color: neonRed,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Assign Owners',
                            icon: Icons.person_add,
                            onTap: () => context.go(RouteConstants.assignOwners),
                            neonRed: neonRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            title: 'Owner Management',
                            icon: Icons.manage_accounts,
                            onTap: () => context.go(RouteConstants.ownerManagement),
                            neonRed: neonRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color neonRed;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.neonRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonRed.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: GoogleFonts.audiowide(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.saira(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color neonRed;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.neonRed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: neonRed.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: neonRed, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.audiowide(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

