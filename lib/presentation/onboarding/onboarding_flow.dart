import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/goal_calculator.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/reminder_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/container_preset_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/weather_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_card.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _currentStep = 0;
  final _pageController = PageController();

  // Step 2: Name
  final _nameController = TextEditingController();

  // Step 3: Body metrics
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  // Step 4: Gender
  String? _selectedGender;

  // Step 5: Activity level
  String _activityLevel = 'sedentary';

  // Step 7: Wake/Sleep
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);

  // Step 9: Calculated goal
  int _calculatedGoal = 2500;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name cannot exceed 10 characters.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_currentStep < 8) {
      // Calculate goal when moving past body metrics step
      if (_currentStep == 4) {
        _calculateGoal();
      }
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _calculateGoal() {
    final weight = double.tryParse(_weightController.text) ?? 70;
    final age = int.tryParse(_ageController.text) ?? 25;

    _calculatedGoal = GoalCalculator.calculateDailyGoal(
      weightKg: weight,
      heightCm: 170,
      age: age,
      gender: _selectedGender,
      activityLevel: _activityLevel,
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _completeOnboarding() async {
    final userId = ref.read(authRepositoryProvider).userId;
    if (userId == null) return;

    // Convert age to approximate dateOfBirth
    final age = int.tryParse(_ageController.text);
    final dateOfBirth = age != null
        ? DateTime(DateTime.now().year - age, 1, 1)
        : null;

    // Preserve email from auth
    final email = ref.read(authRepositoryProvider).currentUser?.email;

    // Update profile
    final profile = UserProfile(
      id: userId,
      name: _nameController.text.trim(),
      email: email,
      weight: double.tryParse(_weightController.text),
      dateOfBirth: dateOfBirth,
      gender: _selectedGender,
      activityLevel: _activityLevel,
      wakeTime: _formatTimeOfDay(_wakeTime),
      sleepTime: _formatTimeOfDay(_sleepTime),
      dailyGoalMl: _calculatedGoal,
      onboardingCompleted: true,
    );

    await ref.read(profileProvider.notifier).updateProfile(profile);

    if (!mounted) return;
    try {
      await ref.read(containerPresetsProvider.notifier).createDefaults();
    } catch (_) {}

    if (!mounted) return;
    try {
      final reminderSettings = ReminderSettings(
        id: const Uuid().v4(),
        userId: userId,
        dndStart: _formatTimeOfDay(_sleepTime),
        dndEnd: _formatTimeOfDay(_wakeTime),
      );
      await ref.read(reminderSettingsProvider.notifier).saveSettings(reminderSettings);
    } catch (_) {}

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        GestureDetector(
                          onTap: _prevStep,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                              ],
                              color: AppColors.surfaceContainerLowest,
                            ),
                            child: const Icon(Icons.arrow_back, size: 18),
                          ),
                        )
                      else
                        const SizedBox(width: 32),
                      Text(
                        'STEP ${_currentStep + 1} OF 9',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: constraints.maxWidth *
                                  ((_currentStep + 1) / 9),
                              color: AppColors.primary,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcome(),
                  _buildNameInput(),
                  _buildBodyMetrics(),
                  _buildGenderSelection(),
                  _buildActivityLevel(),
                  _buildLocationPermission(),
                  _buildSleepSchedule(),
                  _buildNotificationPermission(),
                  _buildGoalReveal(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent({
    required String title,
    String? subtitle,
    required Widget content,
    String? buttonLabel,
    VoidCallback? onNext,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          content,
          const SizedBox(height: AppSpacing.lg),
          NeuButton(
            label: buttonLabel ?? 'Continue',
            isFullWidth: true,
            onPressed: onNext ?? _nextStep,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  // Step 0: Welcome
  Widget _buildWelcome() {
    return _buildStepContent(
      title: 'WELCOME TO SIPLY',
      subtitle: 'Your hydration companion',
      content: Column(
        children: [
          NeuCard.primary(
            child: Row(
              children: [
                const Text('💧', style: TextStyle(fontSize: 32)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Track your daily water intake and build healthy habits.',
                    style: AppTypography.bodyLg.copyWith(color: AppColors.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGutter),
          NeuCard.secondary(
            child: Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 32)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Get smart reminders to stay on track throughout the day.',
                    style: AppTypography.bodyLg.copyWith(color: AppColors.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGutter),
          NeuCard(
            backgroundColor: AppColors.tertiaryContainer,
            child: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 32)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Visualize your hydration trends and crush your goals.',
                    style: AppTypography.bodyLg.copyWith(color: AppColors.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      buttonLabel: 'Get Started',
    );
  }

  // Step 1: Name
  Widget _buildNameInput() {
    return _buildStepContent(
      title: 'WHAT\'S YOUR NAME?',
      subtitle: 'We\'ll use this to personalize your experience.',
      content: NeuInput(
        label: 'Your Name',
        hint: 'Enter your name',
        controller: _nameController,
      ),
    );
  }

  // Step 2: Body metrics
  // Step 2: Body metrics
  Widget _buildBodyMetrics() {
    return _buildStepContent(
      title: 'YOUR BODY METRICS',
      subtitle: 'Used to calculate your ideal daily water goal.',
      content: Column(
        children: [
          NeuInput(
            label: 'Weight (kg)',
            hint: '70',
            controller: _weightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          NeuInput(
            label: 'Age',
            hint: '25',
            controller: _ageController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // Step 3: Gender
  Widget _buildGenderSelection() {
    return _buildStepContent(
      title: 'YOUR GENDER',
      subtitle: 'Optional — helps fine-tune your hydration goal.',
      content: Column(
        children: [
          ...[
            ('Male', Icons.male),
            ('Female', Icons.female),
            ('Other', Icons.transgender),
          ].map((g) {
            final isSelected = _selectedGender == g.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.cardGutter),
              child: NeuCard(
                backgroundColor: isSelected
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainerLowest,
                onTap: () => setState(() => _selectedGender = g.$1),
                child: Row(
                  children: [
                    Icon(g.$2,
                        color: isSelected
                            ? AppColors.onSecondaryContainer
                            : AppColors.onSurface),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      g.$1.toUpperCase(),
                      style: AppTypography.bodyLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.onSecondaryContainer
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () {
              setState(() => _selectedGender = null);
              _nextStep();
            },
            child: Text(
              'SKIP',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Activity level
  Widget _buildActivityLevel() {
    return _buildStepContent(
      title: 'ACTIVITY LEVEL',
      subtitle: 'How active are you on a typical day?',
      content: Column(
        children: [
          ...[
            ('sedentary', 'SEDENTARY', 'Desk job, minimal exercise', '🪑'),
            ('active', 'ACTIVE', 'Regular exercise, on your feet', '🏃'),
            ('athlete', 'ATHLETE', 'Intense daily training', '💪'),
          ].map((a) {
            final isSelected = _activityLevel == a.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.cardGutter),
              child: NeuCard(
                backgroundColor: isSelected
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainerLowest,
                onTap: () => setState(() => _activityLevel = a.$1),
                child: Row(
                  children: [
                    Text(a.$4, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.$2,
                            style: AppTypography.bodyLg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.onSecondaryContainer
                                  : AppColors.onSurface,
                            ),
                          ),
                          Text(
                            a.$3,
                            style: AppTypography.bodyMd.copyWith(
                              color: isSelected
                                  ? AppColors.onSecondaryContainer
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Step 5: Location permission
  Widget _buildLocationPermission() {
    return _buildStepContent(
      title: 'ENABLE LOCATION',
      subtitle:
          'So we can suggest extra water on hot days based on your local weather.',
      content: NeuCard.primary(
        child: Column(
          children: [
            const Text('🌤️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Weather-based hydration tips need your location.',
              style: AppTypography.bodyLg
                  .copyWith(color: AppColors.onPrimaryContainer),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      buttonLabel: 'Enable Location',
      onNext: () async {
        await Geolocator.requestPermission();
        await ref.read(weatherProvider.notifier).loadWeather();
        _nextStep();
      },
    );
  }

  // Step 6: Sleep schedule
  Widget _buildSleepSchedule() {
    return _buildStepContent(
      title: 'YOUR SCHEDULE',
      subtitle:
          'We\'ll use this to set your Do-Not-Disturb reminder window.',
      content: Column(
        children: [
          NeuCard(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _wakeTime,
              );
              if (time != null) setState(() => _wakeTime = time);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WAKE UP TIME',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      _formatTimeOfDay(_wakeTime),
                      style: AppTypography.numberMd
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ],
                ),
                const Text('☀️', style: TextStyle(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGutter),
          NeuCard(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _sleepTime,
              );
              if (time != null) setState(() => _sleepTime = time);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLEEP TIME',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      _formatTimeOfDay(_sleepTime),
                      style: AppTypography.numberMd
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ],
                ),
                const Text('🌙', style: TextStyle(fontSize: 28)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 7: Notification permission
  Widget _buildNotificationPermission() {
    return _buildStepContent(
      title: 'ENABLE NOTIFICATIONS',
      subtitle:
          'Get timely reminders to stay hydrated throughout the day.',
      content: NeuCard.secondary(
        child: Column(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We\'ll send you gentle nudges during your active hours. Never during your sleep.',
              style: AppTypography.bodyLg
                  .copyWith(color: AppColors.onSecondaryContainer),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      buttonLabel: 'Enable Notifications',
      onNext: () async {
        await Permission.notification.request();
        _nextStep();
      },
    );
  }

  // Step 8: Goal reveal (Final Step)
  Widget _buildGoalReveal() {
    _calculateGoal();
    return _buildStepContent(
      title: 'YOUR DAILY GOAL',
      subtitle:
          'Based on your body metrics and activity level. You can adjust this anytime from your profile.',
      content: NeuCard.primary(
        child: Column(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_calculatedGoal}ml',
              style: AppTypography.displayLg.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
            Text(
              '${(_calculatedGoal / 1000).toStringAsFixed(1)} LITRES PER DAY',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onPrimaryContainer.withValues(alpha: 0.7),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      buttonLabel: 'Finish Setup',
      onNext: () async {
        await _completeOnboarding();
      },
    );
  }
}
