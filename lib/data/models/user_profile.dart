import 'avatar_options.dart';

class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? country;
  final DateTime? dateOfBirth;
  final double? weight;
  final double? height;
  final String? gender;
  final String activityLevel;
  final String? wakeTime;
  final String? sleepTime;
  final int dailyGoalMl;
  final String unitPreference;
  final String themePreference;
  final String? avatarUrl;
  final String? avatarSeed;
  final String? avatarBackgroundColor;
  final String? avatarShapeColor;
  final String? avatarFlip;
  final int? avatarRotate;
  final int? avatarScale;
  final int streakCurrent;
  final int streakLongest;
  final int streakFreezesAvailable;
  final int streakFreezesUsedThisMonth;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.country,
    this.dateOfBirth,
    this.weight,
    this.height,
    this.gender,
    this.activityLevel = 'sedentary',
    this.wakeTime,
    this.sleepTime,
    this.dailyGoalMl = 2500,
    this.unitPreference = 'metric',
    this.themePreference = 'light',
    this.avatarUrl,
    this.avatarSeed,
    this.avatarBackgroundColor,
    this.avatarShapeColor,
    this.avatarFlip,
    this.avatarRotate,
    this.avatarScale,
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.streakFreezesAvailable = 2,
    this.streakFreezesUsedThisMonth = 0,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  AvatarOptions toAvatarOptions() {
    return AvatarOptions(
      seed: avatarSeed ?? (name != null && name!.isNotEmpty ? name! : (id.isNotEmpty ? id : 'h2o_user')),
      backgroundColor: avatarBackgroundColor ?? 'FFDE00',
      shapeColor: avatarShapeColor ?? '1976D2',
      flip: avatarFlip ?? 'none',
      rotate: avatarRotate ?? 0,
      scale: avatarScale ?? 100,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      dateOfBirth: _parseDob(json['date_of_birth']),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      activityLevel: json['activity_level'] as String? ?? 'sedentary',
      wakeTime: json['wake_time'] as String?,
      sleepTime: json['sleep_time'] as String?,
      dailyGoalMl: json['daily_goal_ml'] as int? ?? 2500,
      unitPreference: json['unit_preference'] as String? ?? 'metric',
      themePreference: json['theme_preference'] as String? ?? 'light',
      avatarUrl: json['avatar_url'] as String?,
      avatarSeed: json['avatar_seed'] as String?,
      avatarBackgroundColor: json['avatar_background_color'] as String?,
      avatarShapeColor: json['avatar_shape_color'] as String?,
      avatarFlip: json['avatar_flip'] as String?,
      avatarRotate: json['avatar_rotate'] as int?,
      avatarScale: json['avatar_scale'] as int?,
      streakCurrent: json['streak_current'] as int? ?? 0,
      streakLongest: json['streak_longest'] as int? ?? 0,
      streakFreezesAvailable: json['streak_freezes_available'] as int? ?? 2,
      streakFreezesUsedThisMonth:
          json['streak_freezes_used_this_month'] as int? ?? 0,
      onboardingCompleted: (json['onboarding_completed'] as bool?) ??
          (json['name'] != null && (json['name'] as String).trim().isNotEmpty),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => toLocalJson();
  Map<String, dynamic> toSupabaseJson() => toCoreSupabaseJson();

  Map<String, dynamic> toCoreSupabaseJson() {
    final map = <String, dynamic>{
      'id': id,
      'daily_goal_ml': dailyGoalMl,
      'activity_level': activityLevel,
      'unit_preference': unitPreference,
      'theme_preference': themePreference,
      'streak_current': streakCurrent,
      'streak_longest': streakLongest,
      'onboarding_completed': onboardingCompleted,
    };
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (phone != null && phone!.trim().isNotEmpty) map['phone'] = phone!.trim();
    if (country != null && country!.trim().isNotEmpty) map['country'] = country!.trim();
    if (dateOfBirth != null) {
      map['date_of_birth'] = _formatDob(dateOfBirth);
    }
    if (weight != null) map['weight'] = weight;
    if (height != null) map['height'] = height;
    if (gender != null) map['gender'] = gender;
    if (wakeTime != null) map['wake_time'] = wakeTime;
    if (sleepTime != null) map['sleep_time'] = sleepTime;
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (avatarSeed != null) map['avatar_seed'] = avatarSeed;
    if (avatarBackgroundColor != null) map['avatar_background_color'] = avatarBackgroundColor;
    if (avatarShapeColor != null) map['avatar_shape_color'] = avatarShapeColor;
    if (avatarFlip != null) map['avatar_flip'] = avatarFlip;
    if (avatarRotate != null) map['avatar_rotate'] = avatarRotate;
    if (avatarScale != null) map['avatar_scale'] = avatarScale;
    return map;
  }

  Map<String, dynamic> toLocalJson() {
    final map = toCoreSupabaseJson();
    if (phone != null) map['phone'] = phone;
    if (country != null) map['country'] = country;
    if (dateOfBirth != null) map['date_of_birth'] = _formatDob(dateOfBirth);
    if (wakeTime != null) map['wake_time'] = wakeTime;
    if (sleepTime != null) map['sleep_time'] = sleepTime;
    if (avatarSeed != null) map['avatar_seed'] = avatarSeed;
    if (avatarBackgroundColor != null) map['avatar_background_color'] = avatarBackgroundColor;
    if (avatarShapeColor != null) map['avatar_shape_color'] = avatarShapeColor;
    if (avatarFlip != null) map['avatar_flip'] = avatarFlip;
    if (avatarRotate != null) map['avatar_rotate'] = avatarRotate;
    if (avatarScale != null) map['avatar_scale'] = avatarScale;
    if (updatedAt != null) map['updated_at'] = updatedAt?.toIso8601String();
    return map;
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? country,
    DateTime? dateOfBirth,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? wakeTime,
    String? sleepTime,
    int? dailyGoalMl,
    String? unitPreference,
    String? themePreference,
    String? avatarUrl,
    String? avatarSeed,
    String? avatarBackgroundColor,
    String? avatarShapeColor,
    String? avatarFlip,
    int? avatarRotate,
    int? avatarScale,
    int? streakCurrent,
    int? streakLongest,
    int? streakFreezesAvailable,
    int? streakFreezesUsedThisMonth,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      unitPreference: unitPreference ?? this.unitPreference,
      themePreference: themePreference ?? this.themePreference,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      avatarBackgroundColor: avatarBackgroundColor ?? this.avatarBackgroundColor,
      avatarShapeColor: avatarShapeColor ?? this.avatarShapeColor,
      avatarFlip: avatarFlip ?? this.avatarFlip,
      avatarRotate: avatarRotate ?? this.avatarRotate,
      avatarScale: avatarScale ?? this.avatarScale,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakLongest: streakLongest ?? this.streakLongest,
      streakFreezesAvailable:
          streakFreezesAvailable ?? this.streakFreezesAvailable,
      streakFreezesUsedThisMonth:
          streakFreezesUsedThisMonth ?? this.streakFreezesUsedThisMonth,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  static DateTime? _parseDob(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      final datePart = value.split('T').first.split(' ').first;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  static String? _formatDob(DateTime? dob) {
    if (dob == null) return null;
    return "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
  }
}
