import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/avatar_options.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../shared/undo_overlay.dart';
import '../widgets/neu_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onSettings;

  const ProfileScreen({super.key, required this.onSettings});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes.clamp(1, 60)} mins ago';
      }
      return '${diff.inHours} hrs ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  String _formatActivity(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light';
      case 'moderate':
        return 'Moderate';
      case 'active':
        return 'Active';
      case 'very_active':
        return 'Very Active';
      default:
        return level.isNotEmpty
            ? level[0].toUpperCase() + level.substring(1)
            : '-';
    }
  }

  IconData _getActivityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return Icons.chair_outlined;
      case 'light':
        return Icons.directions_walk;
      case 'moderate':
        return Icons.directions_bike;
      case 'active':
        return Icons.directions_run;
      case 'very_active':
        return Icons.bolt;
      default:
        return Icons.fitness_center;
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    UndoOverlay.show(
      context,
      message: '${label.toUpperCase()} COPIED',
      durationSeconds: 2,
      onUndo: () {},
    );
  }

  void _showAvatarActionSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(AppSpacing.screenMargin),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AVATAR OPTIONS',
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.black, width: 2),
                        color: const Color(0xFFFFDE00),
                      ),
                      child: const Icon(Icons.close, size: 18, color: AppColors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _actionTile(
                icon: Icons.shuffle,
                title: 'Shuffle Avatar',
                subtitle: 'Instantly generate a new random avatar seed with live preview',
                color: const Color(0xFFFFDE00),
                onTap: () {
                  Navigator.of(context).pop();
                  _showShuffleAvatarSheet(context, profile);
                },
              ),
              const SizedBox(height: 10),
              _actionTile(
                icon: Icons.palette_outlined,
                title: 'Customize Avatar',
                subtitle: 'Change colors, shapes, rotation, and style',
                color: const Color(0xFF0047FF),
                iconColor: Colors.white,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/avatar-selection');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Color iconColor = AppColors.black,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppColors.black, width: 2),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.black),
          ],
        ),
      ),
    );
  }

  void _showShuffleAvatarSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShuffleAvatarModal(profile: profile),
    );
  }

  void _openUnifiedEditSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UnifiedEditSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: profileAsync.when(
          data: (p) {
            if (p == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0047FF)),
              );
            }

            final avatarOptions = p.toAvatarOptions();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Bar + Settings Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROFILE',
                        style: AppTypography.headlineLg.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                          letterSpacing: -1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSettings,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            size: 22,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hero Identity Block (Replaces flat blue rectangle)
                  _buildIdentityHeroBlock(context, p, avatarOptions),

                  const SizedBox(height: 16),

                  // Section 1: Personal Information Card (White Tint)
                  _buildSectionHeader('PERSONAL INFORMATION'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // surface-container-lowest
                      border: Border.all(color: AppColors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoRow('NAME', p.name ?? '-'),
                        _divider(),
                        _infoRow('EMAIL', p.email ?? '-'),
                        _divider(),
                        _infoRow('PHONE', p.phone ?? '-'),
                        _divider(),
                        _infoRow('COUNTRY', p.country ?? '-'),
                        _divider(),
                        _infoRow(
                          'DATE OF BIRTH',
                          p.dateOfBirth != null
                              ? DateFormat('MMM d, yyyy').format(p.dateOfBirth!)
                              : '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 2: Health Profile Card (Subtle Grey Tint #F3F3F3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('HEALTH PROFILE'),
                      Text(
                        'Last updated ${_formatRelativeTime(p.updatedAt ?? p.createdAt)}',
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3), // surface-container-low
                      border: Border.all(color: AppColors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _healthMetricChip(
                                label: 'WEIGHT',
                                value: p.weight != null ? '${p.weight!.toStringAsFixed(1)} kg' : '- kg',
                                icon: Icons.scale_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _healthMetricChip(
                                label: 'HEIGHT',
                                value: p.height != null ? '${p.height!.toStringAsFixed(0)} cm' : '- cm',
                                icon: Icons.height,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10, height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _healthMetricChip(
                                label: 'AGE',
                                value: p.dateOfBirth != null
                                    ? '${DateTime.now().year - p.dateOfBirth!.year} yrs'
                                    : '- yrs',
                                icon: Icons.cake_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _healthMetricChip(
                                label: 'GENDER',
                                value: p.gender != null && p.gender!.isNotEmpty
                                    ? p.gender![0].toUpperCase() + p.gender!.substring(1)
                                    : '-',
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _healthMetricChip(
                          label: 'ACTIVITY LEVEL',
                          value: _formatActivity(p.activityLevel),
                          icon: _getActivityIcon(p.activityLevel),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 3: Daily Goal Card (Manual Override Pencil Chip)
                  _buildSectionHeader('DAILY GOAL'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0047FF),
                            border: Border.all(color: AppColors.black, width: 2),
                          ),
                          child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TARGET INTAKE',
                                style: AppTypography.labelSm.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                              Text(
                                '${(p.dailyGoalMl / 1000).toStringAsFixed(1)}L / day (${p.dailyGoalMl} ml)',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Restyled Manual Goal Override Chip (Sunny Yellow)
                        GestureDetector(
                          onTap: () => _openUnifiedEditSheet(context, p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDE00),
                              border: Border.all(color: AppColors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 14, color: AppColors.black),
                                const SizedBox(width: 4),
                                Text(
                                  'CHANGE',
                                  style: AppTypography.labelSm.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0047FF)),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  // Identity Hero Block with geometric pattern accents & entrance animation
  Widget _buildIdentityHeroBlock(
      BuildContext context, UserProfile profile, AvatarOptions avatarOptions) {
    final memberDate = profile.createdAt != null
        ? DateFormat('d MMMM yyyy').format(profile.createdAt!)
        : '30 July 2026';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0047FF), // Electric Blue #004AC6 / #0047FF
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(5, 5)),
        ],
      ),
      child: Stack(
        children: [
          // Background Geometric Accents (Rotated Neubrutalist Shapes)
          Positioned(
            left: -15,
            top: -15,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDE00).withValues(alpha: 0.35),
                  border: Border.all(color: AppColors.black, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 40,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD81B60).withValues(alpha: 0.35),
                  border: Border.all(color: AppColors.black, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Transform.rotate(
              angle: 0.6,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDE00).withValues(alpha: 0.25),
                  border: Border.all(color: AppColors.black, width: 2),
                ),
              ),
            ),
          ),

          // Main Hero Content Column
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // Avatar with Camera/Edit Badge
                GestureDetector(
                  onTap: () => _showAvatarActionSheet(context, profile),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey(avatarOptions.seed),
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarOptions.buildWidget(size: 90),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDE00),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.black, width: 2),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                            ],
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            size: 16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  (profile.name ?? 'User').toUpperCase(),
                  style: AppTypography.headlineLg.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Email + Verified Check + Long-press Copy
                if (profile.email != null && profile.email!.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        _copyToClipboard(context, profile.email!, 'Email'),
                    onLongPress: () =>
                        _copyToClipboard(context, profile.email!, 'Email'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: Color(0xFFFFDE00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.email!,
                          style: AppTypography.bodyMd.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 4),
                Text(
                  'Member since $memberDate',
                  style: AppTypography.labelSm.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // ONE Single Unified "EDIT PROFILE" Button
                NeuButton(
                  label: 'EDIT PROFILE',
                  backgroundColor: const Color(0xFFFFDE00),
                  textColor: AppColors.black,
                  icon: Icons.edit_outlined,
                  onPressed: () => _openUnifiedEditSheet(context, profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headlineMd.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _healthMetricChip({
    required String label,
    required String value,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0047FF)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppTypography.bodyLg.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyLg.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1.5,
      color: AppColors.black.withValues(alpha: 0.15),
    );
  }
}

/// Unified Edit Sheet Component
class _UnifiedEditSheet extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _UnifiedEditSheet({required this.profile});

  @override
  ConsumerState<_UnifiedEditSheet> createState() => _UnifiedEditSheetState();
}

class _UnifiedEditSheetState extends ConsumerState<_UnifiedEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _goalController;
  DateTime? _selectedDob;
  late String _selectedGender;
  late String _selectedActivity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name ?? '');
    _phoneController = TextEditingController(text: p.phone ?? '');
    _countryController = TextEditingController(text: p.country ?? '');
    _weightController = TextEditingController(text: p.weight?.toString() ?? '');
    _heightController = TextEditingController(text: p.height?.toString() ?? '');
    _goalController = TextEditingController(text: p.dailyGoalMl.toString());
    _selectedDob = p.dateOfBirth;
    _selectedGender = (p.gender ?? 'male').toLowerCase();
    _selectedActivity = p.activityLevel.toLowerCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  int _calculateRecommendedGoal(double weightKg, double heightCm, int age, String gender, String activity) {
    // Mifflin-St Jeor Formula BMR estimate
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + (gender == 'male' ? 5 : -161);
    double multiplier = 1.2;
    switch (activity) {
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    final calc = (bmr * multiplier * 1.0).round();
    return calc.clamp(1500, 5000);
  }

  IconData _getActIcon(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return Icons.chair_outlined;
      case 'light':
        return Icons.directions_walk;
      case 'moderate':
        return Icons.directions_bike;
      case 'active':
        return Icons.directions_run;
      case 'very_active':
        return Icons.bolt;
      default:
        return Icons.fitness_center;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final newWeight = double.tryParse(_weightController.text);
    final newHeight = double.tryParse(_heightController.text);
    final newGoalInput = int.tryParse(_goalController.text);

    bool healthChanged = (newWeight != widget.profile.weight) ||
        (newHeight != widget.profile.height) ||
        (_selectedGender != (widget.profile.gender ?? 'male').toLowerCase()) ||
        (_selectedActivity != widget.profile.activityLevel.toLowerCase());

    int finalGoal = newGoalInput ?? widget.profile.dailyGoalMl;
    if (healthChanged && newWeight != null && newHeight != null && _selectedDob != null) {
      final age = DateTime.now().year - _selectedDob!.year;
      finalGoal = _calculateRecommendedGoal(newWeight, newHeight, age, _selectedGender, _selectedActivity);
    }

    final updatedProfile = widget.profile.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      country: _countryController.text.trim(),
      dateOfBirth: _selectedDob,
      weight: newWeight,
      height: newHeight,
      gender: _selectedGender,
      activityLevel: _selectedActivity,
      dailyGoalMl: finalGoal,
      updatedAt: DateTime.now(),
    );

    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(healthChanged
              ? 'Profile saved! Daily Goal updated to $finalGoal ml'
              : 'Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        border: Border(
          top: BorderSide(color: AppColors.black, width: 4),
          left: BorderSide(color: AppColors.black, width: 4),
          right: BorderSide(color: AppColors.black, width: 4),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F3F3),
              border: Border(bottom: BorderSide(color: AppColors.black, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EDIT PROFILE',
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDE00),
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 16, color: AppColors.black),
                        const SizedBox(width: 4),
                        Text(
                          'CANCEL',
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  Text(
                    'PERSONAL INFORMATION',
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInputField('NAME', _nameController, hint: 'Your full name'),
                  const SizedBox(height: 12),
                  _buildInputField('PHONE', _phoneController, hint: '+1 234 567 8900', keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildInputField('COUNTRY', _countryController, hint: 'United States'),
                  const SizedBox(height: 12),

                  // Date of Birth Field with DatePicker
                  Text(
                    'DATE OF BIRTH',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDob ?? DateTime(1995, 1, 1),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDob = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.black, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDob != null
                                ? DateFormat('MMM d, yyyy').format(_selectedDob!)
                                : 'Select Date of Birth',
                            style: AppTypography.bodyLg.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.black),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Health Profile Section
                  Text(
                    'HEALTH PROFILE',
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField('WEIGHT (KG)', _weightController, hint: '70', keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField('HEIGHT (CM)', _heightController, hint: '175', keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Gender Selection
                  Text(
                    'GENDER',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['male', 'female', 'other'].map((g) {
                      final isSelected = _selectedGender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = g),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
                              border: Border.all(color: AppColors.black, width: 2.5),
                            ),
                            child: Center(
                              child: Text(
                                g.toUpperCase(),
                                style: AppTypography.labelSm.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Activity Level Selection
                  Text(
                    'ACTIVITY LEVEL',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['sedentary', 'light', 'moderate', 'active', 'very_active'].map((act) {
                      final isSelected = _selectedActivity == act;
                      final icon = _getActIcon(act);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedActivity = act),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
                            border: Border.all(color: AppColors.black, width: 2.5),
                            boxShadow: isSelected
                                ? const [BoxShadow(color: AppColors.black, offset: Offset(2, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: AppColors.black),
                              const SizedBox(width: 6),
                              Text(
                                act.replaceAll('_', ' ').toUpperCase(),
                                style: AppTypography.labelSm.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Daily Goal Override Field
                  Text(
                    'DAILY GOAL (ML)',
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildInputField('GOAL IN ML', _goalController, hint: '2500', keyboardType: TextInputType.number),

                  const SizedBox(height: 28),

                  // Single Full-width SAVE CHANGES Button
                  GestureDetector(
                    onTap: _isSaving ? null : _saveChanges,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047FF),
                        border: Border.all(color: AppColors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'SAVE CHANGES',
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Focus(
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isFocused ? const Color(0xFF0047FF) : AppColors.black,
                    width: isFocused ? 3 : 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(2.5, 2.5)),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: AppTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTypography.bodyMd.copyWith(color: const Color(0xFFAAAAAA)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Interactive Shuffle Avatar Modal with live preview & stay on Profile screen
class _ShuffleAvatarModal extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _ShuffleAvatarModal({required this.profile});

  @override
  ConsumerState<_ShuffleAvatarModal> createState() => _ShuffleAvatarModalState();
}

class _ShuffleAvatarModalState extends ConsumerState<_ShuffleAvatarModal> {
  late AvatarOptions _previewOptions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentOpts = widget.profile.toAvatarOptions();
    _previewOptions = currentOpts.copyWith(seed: _randomSeed());
  }

  String _randomSeed() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return List.generate(8, (i) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _shuffleNext() {
    HapticFeedback.lightImpact();
    setState(() {
      _previewOptions = _previewOptions.copyWith(seed: _randomSeed());
    });
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    await ref.read(profileProvider.notifier).saveAvatarOptions(_previewOptions);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.black,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        border: Border(
          top: BorderSide(color: AppColors.black, width: 4),
          left: BorderSide(color: AppColors.black, width: 4),
          right: BorderSide(color: AppColors.black, width: 4),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SHUFFLE AVATAR',
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black, width: 2),
                      color: const Color(0xFFFFDE00),
                    ),
                    child: const Icon(Icons.close, size: 18, color: AppColors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap SHUFFLE AGAIN to preview avatars, then save your favorite!',
              style: AppTypography.bodyMd.copyWith(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Live Preview Card Box
            Center(
              child: Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(5, 5)),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_previewOptions.seed),
                    child: _previewOptions.buildWidget(size: 175),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Seed Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              child: Text(
                'SEED: #${_previewOptions.seed}',
                style: AppTypography.labelSm.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _shuffleNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDE00),
                        border: Border.all(color: AppColors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.casino, color: AppColors.black, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'SHUFFLE AGAIN',
                            style: AppTypography.headlineMd.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSaving ? null : _saveAvatar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047FF),
                        border: Border.all(color: AppColors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SAVE AVATAR',
                                    style: AppTypography.headlineMd.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
