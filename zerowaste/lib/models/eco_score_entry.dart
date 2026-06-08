class EcoScoreEntry {
  const EcoScoreEntry({
    required this.score,
    required this.reason,
    required this.rankLabel,
    required this.createdAt,
  });

  final int score;
  final String reason;
  final String rankLabel;
  final DateTime createdAt;

  factory EcoScoreEntry.fromMap(Map<String, dynamic> map) {
    return EcoScoreEntry(
      score: (map['score'] as num?)?.round() ?? 0,
      reason: map['reason'] as String? ?? 'Eco activity',
      rankLabel: map['rank_label'] as String? ?? 'Community member',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
