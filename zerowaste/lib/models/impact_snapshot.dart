class ImpactSnapshot {
  const ImpactSnapshot({
    required this.plasticWasteReduction,
    required this.foodWasteReduction,
    required this.packagingReduction,
    required this.streakDays,
    required this.ecoScore,
    required this.totalWasteReduced,
    required this.totalRecycledItems,
    required this.totalFoodSaved,
    required this.ranking,
    required this.weeklyProgress,
    required this.monthlyStats,
    required this.activities,
    required this.scoreHistory,
  });

  final int plasticWasteReduction;
  final int foodWasteReduction;
  final int packagingReduction;
  final int streakDays;
  final int ecoScore;
  final double totalWasteReduced;
  final int totalRecycledItems;
  final double totalFoodSaved;
  final String ranking;
  final List<int> weeklyProgress;
  final List<int> monthlyStats;
  final List<EcoActivity> activities;
  final List<int> scoreHistory;

  factory ImpactSnapshot.fromMap(Map<String, dynamic> map) {
    final progress = map['weekly_progress'];
    final monthly = map['monthly_stats'];
    final activities = map['activities'];
    final history = map['score_history'];

    return ImpactSnapshot(
      plasticWasteReduction: map['plastic_waste_reduction'] as int? ?? 0,
      foodWasteReduction: map['food_waste_reduction'] as int? ?? 0,
      packagingReduction: map['packaging_reduction'] as int? ?? 0,
      streakDays: map['streak_days'] as int? ?? 0,
      ecoScore: map['eco_score'] as int? ?? 0,
      totalWasteReduced:
          (map['total_waste_reduced'] as num?)?.toDouble() ?? 0,
      totalRecycledItems: map['total_recycled_items'] as int? ?? 0,
      totalFoodSaved: (map['total_food_saved'] as num?)?.toDouble() ?? 0,
      ranking: map['ranking'] as String? ?? 'Starter',
      weeklyProgress: progress is List
          ? progress.map((value) => (value as num).round()).toList()
          : const [],
      monthlyStats: monthly is List
          ? monthly.map((value) => (value as num).round()).toList()
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
      scoreHistory: history is List
          ? history.map((value) => (value as num).round()).toList()
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
