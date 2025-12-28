import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class OwnerManagementPage extends StatelessWidget {
  const OwnerManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color neonRed = const Color(0xFFFF1744);
    final Color darkBackground = const Color(0xFF0A0A0A);
    final Color darkSurface = const Color(0xFF1A1A1A);
    final Color darkCard = const Color(0xFF2A2A2A);

    return BlocProvider(
      create: (context) {
        try {
          return di.sl<AdminBloc>()..add(LoadOwnersEvent());
        } catch (e) {
          print('❌ Error creating AdminBloc: $e');
          rethrow;
        }
      },
      child: Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          title: Text(
            'OWNER MANAGEMENT',
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
        body: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is PasswordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Password Reset Successfully!',
                              style: GoogleFonts.audiowide(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${state.email}',
                        style: GoogleFonts.saira(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New Temp Password: ${state.temporaryPassword}',
                        style: GoogleFonts.audiowide(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 15),
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                ),
              );
            } else if (state is AdminError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: GoogleFonts.saira(color: Colors.white)),
                  backgroundColor: neonRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const LoadingWidget(message: 'LOADING OWNERS...');
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
                        context.read<AdminBloc>().add(LoadOwnersEvent());
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: neonRed),
                      child: Text('RETRY', style: GoogleFonts.audiowide()),
                    ),
                  ],
                ),
              );
            }

            if (state is OwnersLoaded) {
              if (state.owners.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, color: neonRed.withOpacity(0.5), size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No Owners Found',
                        style: GoogleFonts.audiowide(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first owner to get started',
                        style: GoogleFonts.saira(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.owners.length,
                itemBuilder: (context, index) {
                  final owner = state.owners[index];
                  return _OwnerCard(
                    owner: owner,
                    neonRed: neonRed,
                    darkCard: darkCard,
                    onResetPassword: (tenantId, email) {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A1A),
                          title: Text(
                            'Reset Password',
                            style: GoogleFonts.audiowide(color: neonRed),
                          ),
                          content: Text(
                            'This will generate a new temporary password for $email. The owner will be required to change it on next login.',
                            style: GoogleFonts.saira(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('CANCEL', style: GoogleFonts.saira(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.read<AdminBloc>().add(ResetOwnerPasswordEvent(tenantId: tenantId));
                              },
                              style: TextButton.styleFrom(foregroundColor: neonRed),
                              child: Text('RESET', style: GoogleFonts.audiowide(color: neonRed)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final Map<String, dynamic> owner;
  final Color neonRed;
  final Color darkCard;
  final Function(String tenantId, String email) onResetPassword;

  const _OwnerCard({
    required this.owner,
    required this.neonRed,
    required this.darkCard,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: neonRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: neonRed, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner['name'] ?? 'No Name',
                      style: GoogleFonts.audiowide(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owner['email'] ?? 'No Email',
                      style: GoogleFonts.saira(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white10),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Phone',
            value: owner['phone'] ?? 'N/A',
            icon: Icons.phone,
            neonRed: neonRed,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Tenant',
            value: owner['tenantName'] ?? 'N/A',
            icon: Icons.business,
            neonRed: neonRed,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Status',
            value: owner['tenantStatus'] ?? 'active',
            icon: Icons.info,
            neonRed: neonRed,
          ),
          const SizedBox(height: 8),
          // Show password (temporary if exists, otherwise show "Password set")
          if (owner['temporaryPassword'] != null && owner['temporaryPassword'].toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Temporary Password:',
                        style: GoogleFonts.saira(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          owner['temporaryPassword'] ?? '',
                          style: GoogleFonts.audiowide(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.orange, size: 20),
                        tooltip: 'Copy password',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: owner['temporaryPassword'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password copied!',
                                style: GoogleFonts.saira(color: Colors.white),
                              ),
                              backgroundColor: Colors.blue,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⚠️ Owner must change password on first login',
                    style: GoogleFonts.saira(
                      color: Colors.orange.withOpacity(0.8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Password set by owner',
                        style: GoogleFonts.saira(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onResetPassword(owner['tenantId'] ?? '', owner['email'] ?? ''),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        'RESET PASSWORD',
                        style: GoogleFonts.audiowide(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color neonRed;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.neonRed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: neonRed, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.saira(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.saira(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

