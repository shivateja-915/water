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

class SignupScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogin;

  const SignupScreen({super.key, required this.onLogin});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(
          () => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      String rawMsg = e.toString().replaceAll('Exception: ', '');
      String msg;
      final lower = rawMsg.toLowerCase();
      if (lower.contains('user already registered') ||
          lower.contains('already exists') ||
          lower.contains('user_already_exists')) {
        msg =
            'An account with this email address already exists! Please tap "Log In" below.';
      } else if (lower.contains('password')) {
        msg = 'Password is weak or invalid. Please choose a password with at least 6 characters.';
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
              Text(
                'CREATE',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                'ACCOUNT',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.secondaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SIGN UP',
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
                    const SizedBox(height: AppSpacing.sm),

                    NeuInput(
                      label: 'Confirm Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: false,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          border: Border.all(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    NeuButton(
                      label: 'Create Account',
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleSignUp,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Center(
                child: GestureDetector(
                  onTap: widget.onLogin,
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'ALREADY HAVE AN ACCOUNT? '),
                        TextSpan(
                          text: 'LOG IN',
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
