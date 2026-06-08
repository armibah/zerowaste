class ImpactSnapshot {
  const ImpactSnapshot({
    required this.plasticWasteReduction,
    required this.foodWasteReduction,
    required this.packagingReduction,
    required this.streakDays,
    required this.ecoScore,
    required this.weeklyProgress,
    required this.activities,
  });

  final int plasticWasteReduction;
  final int foodWasteReduction;
  final int packagingReduction;
  final int streakDays;
  final int ecoScore;
  final List<int> weeklyProgress;
  final List<EcoActivity> activities;

  factory ImpactSnapshot.fromMap(Map<String, dynamic> map) {
    final progress = map['weekly_progress'];
    final activities = map['activities'];

    return ImpactSnapshot(
      plasticWasteReduction: map['plastic_waste_reduction'] as int? ?? 0,
      foodWasteReduction: map['food_waste_reduction'] as int? ?? 0,
      packagingReduction: map['packaging_reduction'] as int? ?? 0,
      streakDays: map['streak_days'] as int? ?? 0,
      ecoScore: map['eco_score'] as int? ?? 0,
      weeklyProgress: progress is List
          ? progress.map((value) => (value as num).round()).toList()
          : const [],
      activities: activities is List
          ? activities
              .map(
                (activity) => EcoActivity.fromMap(
                  Map<String, dynamic>.from(activity as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class EcoActivity {
  const EcoActivity({
    required this.title,
    required this.subtitle,
    required this.iconName,
  });

  final String title;
  final String subtitle;
  final String iconName;

  factory EcoActivity.fromMap(Map<String, dynamic> map) {
    return EcoActivity(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'eco',
    );
  }
}