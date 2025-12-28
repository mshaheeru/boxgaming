import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../core/constants/route_constants.dart';
import '../../../shared/utils/role_helper.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final user = state.user;
        final isOwner = RoleHelper.isOwner(user);
        final isAdmin = RoleHelper.isAdmin(user);

        return Drawer(
          backgroundColor: const Color(0xFF0A0A0A),
          child: SafeArea(
            child: Column(
              children: [
                // User Info Header
                _UserHeader(user: user),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      if (!isOwner && !isAdmin) ...[
                        // Customer Navigation
                        _DrawerTile(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          route: RouteConstants.root,
                          onTap: () => _navigateAndClose(context, RouteConstants.root),
                          index: 0,
                        ),
                        _DrawerTile(
                          icon: Icons.sports_esports_rounded,
                          title: 'Venues',
                          route: RouteConstants.venuesList,
                          onTap: () => _navigateAndClose(context, RouteConstants.venuesList),
                          index: 1,
                        ),
                        _DrawerTile(
                          icon: Icons.calendar_today_rounded,
                          title: 'My Bookings',
                          route: RouteConstants.myBookings,
                          onTap: () => _navigateAndClose(context, RouteConstants.myBookings),
                          index: 2,
                        ),
                      ] else if (isOwner && !isAdmin) ...[
                        // Owner Navigation (not admin)
                        _DrawerTile(
                          icon: Icons.dashboard_rounded,
                          title: 'Dashboard',
                          route: RouteConstants.ownerDashboard,
                          onTap: () => _navigateAndClose(context, RouteConstants.ownerDashboard),
                          index: 0,
                        ),
                        _DrawerTile(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'QR Scanner',
                          route: RouteConstants.qrScanner,
                          onTap: () => _navigateAndClose(context, RouteConstants.qrScanner),
                          index: 1,
                        ),
                      ] else if (isAdmin) ...[
                        // Admin Navigation
                        _DrawerTile(
                          icon: Icons.dashboard_rounded,
                          title: 'Dashboard',
                          route: RouteConstants.adminDashboard,
                          onTap: () => _navigateAndClose(context, RouteConstants.adminDashboard),
                          index: 0,
                        ),
                        _DrawerTile(
                          icon: Icons.person_add_rounded,
                          title: 'Assign Owners',
                          route: RouteConstants.assignOwners,
                          onTap: () => _navigateAndClose(context, RouteConstants.assignOwners),
                          index: 1,
                        ),
                        _DrawerTile(
                          icon: Icons.manage_accounts_rounded,
                          title: 'Owner Management',
                          route: RouteConstants.ownerManagement,
                          onTap: () => _navigateAndClose(context, RouteConstants.ownerManagement),
                          index: 2,
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFF1744).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Common Items
                      _DrawerTile(
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        route: null,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Profile page coming soon',
                                style: GoogleFonts.saira(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFFFF1744),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        index: 10,
                      ),
                      _DrawerTile(
                        icon: Icons.settings_rounded,
                        title: 'Settings',
                        route: null,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Settings page coming soon',
                                style: GoogleFonts.saira(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFFFF1744),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        index: 11,
                      ),
                      _DrawerTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        route: null,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Help page coming soon',
                                style: GoogleFonts.saira(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFFFF1744),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        index: 12,
                      ),
                    ],
                  ),
                ),
                
                // Logout Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF1744).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    left: 16,
                    right: 16,
                  ),
                  child: _LogoutButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateAndClose(BuildContext context, String route) {
    // Close drawer first, then navigate after a frame to avoid context issues
    Navigator.pop(context);
    // Use Future.microtask to ensure drawer is closed before navigation
    Future.microtask(() {
      if (context.mounted) {
        context.go(route);
      }
    });
  }
}

class _UserHeader extends StatefulWidget {
  final dynamic user;

  const _UserHeader({required this.user});

  @override
  State<_UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<_UserHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF1744).withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF1744).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              // Avatar with glow effect
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1744).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFFF1744),
                  child: Text(
                    (widget.user.name?.isNotEmpty == true
                            ? widget.user.name![0].toUpperCase()
                            : widget.user.phone[0].toUpperCase()),
                    style: GoogleFonts.audiowide(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.user.name ?? 'User').toUpperCase(),
                      style: GoogleFonts.audiowide(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.phone,
                      style: GoogleFonts.saira(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF1744).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.user.role.toString().split('.').last.toUpperCase(),
                        style: GoogleFonts.saira(
                          color: const Color(0xFFFF1744),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? route;
  final VoidCallback onTap;
  final int index;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.route,
    required this.onTap,
    required this.index,
  });

  @override
  State<_DrawerTile> createState() => _DrawerTileState();
}

class _DrawerTileState extends State<_DrawerTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isSelected = widget.route != null && currentRoute == widget.route;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color(0xFFFF1744).withOpacity(0.2)
                : _isHovered
                    ? const Color(0xFFFF1744).withOpacity(0.1)
                    : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: const Color(0xFFFF1744).withOpacity(0.5),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF1744).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _isHovered = true),
              onTapUp: (_) => setState(() => _isHovered = false),
              onTapCancel: () => setState(() => _isHovered = false),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF1744)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isSelected
                            ? Colors.white
                            : _isHovered
                                ? const Color(0xFFFF1744)
                                : Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: GoogleFonts.saira(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected
                              ? const Color(0xFFFF1744)
                              : Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF1744),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton();

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return previous != current;
      },
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else if (state is AuthError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.saira(color: Colors.white),
                ),
                backgroundColor: const Color(0xFFFF1744),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF1744).withOpacity(
                  0.3 + (_pulseController.value * 0.2),
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1744).withOpacity(
                    0.2 + (_pulseController.value * 0.1),
                  ),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                onTapDown: (_) => setState(() => _isHovered = true),
                onTapUp: (_) => setState(() => _isHovered = false),
                onTapCancel: () => setState(() => _isHovered = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _isHovered
                        ? const Color(0xFFFF1744).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFFF1744),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'LOGOUT',
                          style: GoogleFonts.audiowide(
                            color: const Color(0xFFFF1744),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFFF1744).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        title: Text(
          'LOGOUT',
          style: GoogleFonts.audiowide(
            color: const Color(0xFFFF1744),
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.saira(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.saira(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFFF1744).withOpacity(0.2),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.microtask(() {
                  if (context.mounted) {
                    context.read<AuthBloc>().add(LogoutEvent());
                  }
                });
              },
              child: Text(
                'LOGOUT',
                style: GoogleFonts.audiowide(
                  color: const Color(0xFFFF1744),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

