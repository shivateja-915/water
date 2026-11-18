import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../widgets/neu_card.dart';

class AboutScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AboutScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header row
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.black,
                            width: AppSpacing.borderWidth),
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
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'ABOUT',
                    style: AppTypography.headlineLg
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Logo + App Name Card
              NeuCard(
                child: Column(
                  children: [
                    // Siply Logo — water drop icon in a styled circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.black,
                            width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.black,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: AppColors.onPrimary,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Siply',
                      style: AppTypography.headlineLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        border: Border.all(
                            color: AppColors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Every Sip Counts',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Siply is a manual hydration companion designed to help you build healthier water-drinking habits through reminders, personalized hydration tracking.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Features section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FEATURES',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      icon: Icons.water_drop_outlined,
                      emoji: '💧',
                      label: 'Hydration\nTracking',
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _featureCard(
                      icon: Icons.notifications_active_outlined,
                      emoji: '🔔',
                      label: 'Reminders',
                      color: AppColors.secondaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      icon: Icons.bar_chart_outlined,
                      emoji: '📊',
                      label: 'Daily\nAnalytics',
                      color: AppColors.tertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _featureCard(
                      icon: Icons.cloud_outlined,
                      emoji: '☁️',
                      label: 'Cloud\nSync',
                      color: AppColors.surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Developed by section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DEVELOPED BY',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              NeuCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'S',
                          style: AppTypography.headlineLg.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shiva',
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'shivashapure21@gmail.com',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Footer
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Siply',
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every Sip Counts 💧',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String emoji,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.black, width: 2),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
