import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_card.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resetPassword(_emailController.text.trim());
      setState(() => _emailSent = true);
    } catch (_) {
      setState(() => _emailSent = true); // Don't reveal if email exists
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
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.black, width: AppSpacing.borderWidth),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        offset: Offset(3, 3),
                      ),
                    ],
                    color: AppColors.surfaceContainerLowest,
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'RESET',
                style: AppTypography.displayLg
                    .copyWith(color: AppColors.primary),
              ),
              Text(
                'PASSWORD',
                style: AppTypography.headlineLgMobile
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_emailSent)
                NeuCard(
                  backgroundColor: AppColors.primaryFixed,
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          size: 48, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'CHECK YOUR EMAIL',
                        style: AppTypography.headlineMd
                            .copyWith(color: AppColors.onPrimaryFixed),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'If an account exists for this email, a reset link has been sent.',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onPrimaryFixedVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeuButton(
                        label: 'Back to Login',
                        onPressed: widget.onBack,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                )
              else
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter your email and we\'ll send you a reset link.',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeuInput(
                        label: 'Email',
                        hint: 'your@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NeuButton(
                        label: 'Send Reset Link',
                        isFullWidth: true,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleReset,
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
