import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/constants/route_constants.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../../../../shared/widgets/app_drawer.dart';

class AssignOwnersPage extends StatefulWidget {
  const AssignOwnersPage({super.key});

  @override
  State<AssignOwnersPage> createState() => _AssignOwnersPageState();
}

class _AssignOwnersPageState extends State<AssignOwnersPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tenantNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _autoGeneratePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tenantNameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleCreateOwner(BuildContext context) {
    print('🔘 Create Owner button pressed');
    if (_formKey.currentState == null) {
      print('❌ Form key is null!');
      return;
    }
    final isValid = _formKey.currentState!.validate();
    print('✅ Form validation result: $isValid');
    if (isValid) {
      print('📤 Dispatching CreateOwnerEvent');
      print('   Email: ${_emailController.text.trim()}');
      print('   Tenant Name: ${_tenantNameController.text.trim()}');
      print('   Name: ${_nameController.text.trim()}');
      print('   Auto-generate: $_autoGeneratePassword');
      
      // Get the bloc from the context that has access to BlocProvider
      final adminBloc = context.read<AdminBloc>();
      if (adminBloc.isClosed) {
        print('❌ AdminBloc is closed!');
        return;
      }
      adminBloc.add(
        CreateOwnerEvent(
          email: _emailController.text.trim(),
          tenantName: _tenantNameController.text.trim(),
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          temporaryPassword: _autoGeneratePassword ? null : _passwordController.text.trim(),
        ),
      );
    } else {
      print('❌ Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color neonRed = const Color(0xFFFF1744);
    final Color darkBackground = const Color(0xFF0A0A0A);
    final Color darkSurface = const Color(0xFF1A1A1A);
    final Color darkCard = const Color(0xFF2A2A2A);

    return BlocProvider(
      create: (context) {
        try {
          return di.sl<AdminBloc>();
        } catch (e) {
          print('❌ Error creating AdminBloc: $e');
          rethrow;
        }
      },
      child: Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          title: Text(
            'ASSIGN OWNERS',
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
          listener: (listenerContext, state) {
          print('🔔 AdminBloc state changed: ${state.runtimeType}');
          if (state is OwnerCreatedSuccess) {
            print('✅ Owner created successfully!');
            print('   Email: ${state.email}');
            print('   Password: ${state.temporaryPassword}');
            
            if (state.email.isEmpty || state.temporaryPassword.isEmpty) {
              print('⚠️ WARNING: Email or password is empty!');
              ScaffoldMessenger.of(listenerContext).showSnackBar(
                SnackBar(
                  content: Text('Owner created but credentials are missing. Please check backend response.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            
            // Show success snackbar
            ScaffoldMessenger.of(listenerContext).clearSnackBars(); // Clear any existing snackbars
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Owner Created Successfully!',
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Temporary Password:',
                                  style: GoogleFonts.saira(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  state.temporaryPassword,
                                  style: GoogleFonts.audiowide(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                            tooltip: 'Copy password',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: state.temporaryPassword));
                              ScaffoldMessenger.of(listenerContext).showSnackBar(
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
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ IMPORTANT: Save these credentials! Password cannot be retrieved later.',
                              style: GoogleFonts.saira(
                                color: Colors.white70,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 15), // Longer duration to see credentials
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            // Clear form
            _emailController.clear();
            _tenantNameController.clear();
            _nameController.clear();
            _passwordController.clear();
            setState(() {
              _autoGeneratePassword = true;
            });
            _formKey.currentState?.reset();
            // Don't auto-navigate - let user see the snackbar and manually navigate if needed
          } else if (state is AdminError) {
            print('❌ Admin error: ${state.message}');
            print('❌ Error state details: ${state.toString()}');
            ScaffoldMessenger.of(listenerContext).clearSnackBars(); // Clear any existing snackbars
            ScaffoldMessenger.of(listenerContext).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: GoogleFonts.saira(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: neonRed,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          },
          builder: (builderContext, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: neonRed.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          size: 48,
                          color: neonRed,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'CREATE NEW OWNER',
                          style: GoogleFonts.audiowide(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: neonRed,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assign a new business owner to the platform',
                          style: GoogleFonts.saira(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form Fields
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.saira(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Owner Email *',
                      hintText: 'owner@indoormania.com',
                      labelStyle: GoogleFonts.saira(color: Colors.white70),
                      hintStyle: GoogleFonts.saira(color: Colors.white54),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF1744)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF1744), width: 2),
                      ),
                      filled: true,
                      fillColor: darkCard,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tenantNameController,
                    style: GoogleFonts.saira(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Business/Tenant Name *',
                      hintText: 'indoormania',
                      labelStyle: GoogleFonts.saira(color: Colors.white70),
                      hintStyle: GoogleFonts.saira(color: Colors.white54),
                      prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFFFF1744)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF1744), width: 2),
                      ),
                      filled: true,
                      fillColor: darkCard,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Business name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.saira(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Owner Name (Optional)',
                      hintText: 'John Doe',
                      labelStyle: GoogleFonts.saira(color: Colors.white70),
                      hintStyle: GoogleFonts.saira(color: Colors.white54),
                      prefixIcon: const Icon(Icons.person_outlined, color: Color(0xFFFF1744)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFF1744), width: 2),
                      ),
                      filled: true,
                      fillColor: darkCard,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Auto-generate password toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: neonRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _autoGeneratePassword,
                          onChanged: (value) {
                            setState(() {
                              _autoGeneratePassword = value ?? true;
                            });
                          },
                          activeColor: neonRed,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-generate Password',
                                style: GoogleFonts.saira(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'A secure password will be generated automatically',
                                style: GoogleFonts.saira(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Password field (only if not auto-generating)
                  if (!_autoGeneratePassword) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: GoogleFonts.saira(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Temporary Password *',
                        hintText: 'Enter temporary password',
                        labelStyle: GoogleFonts.saira(color: Colors.white70),
                        hintStyle: GoogleFonts.saira(color: Colors.white54),
                        prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFFFF1744)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFF1744), width: 2),
                        ),
                        filled: true,
                        fillColor: darkCard,
                      ),
                      validator: (value) {
                        if (!_autoGeneratePassword && (value == null || value.trim().isEmpty)) {
                          return 'Password is required';
                        }
                        if (!_autoGeneratePassword && value != null && value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state is AdminLoading ? null : () => _handleCreateOwner(builderContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: neonRed.withOpacity(0.5),
                      ),
                      child: state is AdminLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'CREATE OWNER',
                              style: GoogleFonts.audiowide(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}

