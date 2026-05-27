
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/constants.dart';
import 'package:smart_attendance_app/domain/enums/auth_state.dart';
import 'package:smart_attendance_app/features/auth/providers/auth_provider.dart';
import 'package:smart_attendance_app/features/auth/widgets/device_change_dialog.dart';
import 'package:smart_attendance_app/shared/widgets/animated_background.dart';
import 'package:smart_attendance_app/shared/widgets/glass_button.dart';
import 'package:smart_attendance_app/shared/widgets/glass_card.dart';
import 'package:smart_attendance_app/shared/widgets/glass_input.dart';
import 'package:smart_attendance_app/shared/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              SasColors.accentEmerald.withValues(alpha: 0.25),
                              SasColors.accentTeal.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: SasColors.accentEmerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: SasColors.accentEmerald,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign in with your university credentials',
                        style: TextStyle(color: SasColors.textMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GlassInput(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'student@university.edu',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email is required';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  
                                  if (kUniversityEmailDomain.isNotEmpty &&
                                      !v.endsWith('@$kUniversityEmailDomain')) {
                                    return 'Use your university email (@$kUniversityEmailDomain)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              GlassInput(
                                controller: _passwordController,
                                label: 'Password',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: SasColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  }),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 8) return 'At least 8 characters';
                                  return null;
                                },
                              ),

                              if (authState.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: SasColors.accentPink.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: SasColors.accentPink.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: SasColors.danger, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              authState.errorMessage!,
                                              style: const TextStyle(
                                                  color: SasColors.danger, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (authState.errorMessage == 'Access forbidden' || authState.errorMessage!.contains('bound')) ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            if (!_formKey.currentState!.validate()) return;
                                            final success = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => DeviceChangeDialog(
                                                email: _emailController.text.trim(),
                                                password: _passwordController.text,
                                              ),
                                            );
                                            if (success == true && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Request sent! Please ask your teacher to approve your new device.'),
                                                  backgroundColor: SasColors.accentEmerald,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.smartphone, size: 16),
                                          label: const Text('Request Device Change'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: SasColors.bgSurface,
                                            foregroundColor: SasColors.accentEmerald,
                                            side: const BorderSide(color: SasColors.accentEmerald),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                              GlassButton(
                                label: 'Sign In',
                                isExpanded: true,
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleLogin,
                                icon: Icons.login_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Students only. Teachers use the web dashboard.',
                        style: TextStyle(color: SasColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            const LoadingOverlay(message: 'Logging in...'),
        ],
      ),
    );
  }
}
