class WasteRecord {
  const WasteRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.unit,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final String unit;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'user_id': userId,
      'type': type,
      'amount': amount,
      'unit': unit,
      'note': note,
    };
  }

  factory WasteRecord.fromMap(Map<String, dynamic> map) {
    return WasteRecord(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'reduced',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'kg',
      note: map['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class EcoScoreEntry {
  const EcoScoreEntry({
    required this.id,
    required this.score,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final int score;
  final String reason;
  final DateTime createdAt;

  factory EcoScoreEntry.fromMap(Map<String, dynamic> map) {
    return EcoScoreEntry(
      id: map['id'] as String,
      score: map['score'] as int? ?? 0,
      reason: map['reason'] as String? ?? 'Eco action',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
