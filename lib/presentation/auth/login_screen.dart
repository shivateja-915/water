import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both your email and password to log in.';
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email,
            password,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      String rawMsg = e.toString().replaceAll('Exception: ', '');
      String msg;
      final lower = rawMsg.toLowerCase();
      if (lower.contains('invalid login credentials') ||
          lower.contains('invalid_credentials') ||
          lower.contains('user_not_found') ||
          lower.contains('invalid email or password') ||
          lower.contains('user not found')) {
        msg =
            'If the email is there, your password is wrong. If the email is not found, please tap Create Account below.';
      } else if (lower.contains('email not confirmed')) {
        msg = 'Email address has not been confirmed yet. Please check your inbox.';
      } else if (lower.contains('too many requests')) {
        msg = 'Too many failed login attempts. Please wait a few moments and try again.';
      } else {
        msg = rawMsg;
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Logo / Title
              Text(
                'SIPLY',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'EVERY SIP COUNTS.',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Login Card
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'LOG IN',
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    NeuInput(
                      label: 'Email',
                      hint: 'your@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    NeuInput(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: false,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          border: Border.all(color: AppColors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.black, offset: Offset(3, 3))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFDE00),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.black,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'WARNING',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: widget.onSignUp,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0047FF),
                                  border: Border.all(
                                      color: AppColors.black, width: 2),
                                ),
                                child: Text(
                                  'CREATE ACCOUNT NOW →',
                                  style: AppTypography.labelSm.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    NeuButton(
                      label: 'Log In',
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleLogin,
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: widget.onForgotPassword,
                      child: Text(
                        'FORGOT PASSWORD?',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              // Sign up link
              Center(
                child: GestureDetector(
                  onTap: widget.onSignUp,
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'DON\'T HAVE AN ACCOUNT? '),
                        TextSpan(
                          text: 'SIGN UP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
