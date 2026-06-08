class WasteRecord {
  const WasteRecord({
    required this.id,
    required this.type,
    required this.amountKg,
    required this.recycledItems,
    required this.foodSavedKg,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double amountKg;
  final int recycledItems;
  final double foodSavedKg;
  final String note;
  final DateTime createdAt;

  factory WasteRecord.fromMap(Map<String, dynamic> map) {
    return WasteRecord(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'waste_reduced',
      amountKg: _toDouble(map['amount_kg']),
      recycledItems: (map['recycled_items'] as num?)?.round() ?? 0,
      foodSavedKg: _toDouble(map['food_saved_kg']),
      note: map['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
