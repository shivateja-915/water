class GoalCalculator {
  GoalCalculator._();

  /// Calculate daily water goal in ml based on user metrics.
  /// Formula: base from weight + activity modifier + age/gender adjustments
  static int calculateDailyGoal({
    required double weightKg,
    required double heightCm,
    required int age,
    String? gender,
    required String activityLevel,
  }) {
    // Base: 35ml per kg of body weight
    double baseGoal = weightKg * 35;

    // Activity level modifier
    switch (activityLevel.toLowerCase()) {
      case 'athlete':
        baseGoal *= 1.4;
        break;
      case 'active':
        baseGoal *= 1.2;
        break;
      case 'sedentary':
      default:
        baseGoal *= 1.0;
        break;
    }

    // Age adjustment (older adults may need slightly less)
    if (age > 55) {
      baseGoal *= 0.9;
    }

    // Gender adjustment
    if (gender?.toLowerCase() == 'female') {
      baseGoal *= 0.9;
    }

    // Round to nearest 50ml
    int goal = ((baseGoal / 50).round() * 50).toInt();

    // Ensure minimum 1500ml and max 5000ml
    return goal.clamp(1500, 5000);
  }
}
