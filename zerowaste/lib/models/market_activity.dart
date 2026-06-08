class MarketActivity {
  const MarketActivity({
    required this.title,
    required this.subtitle,
    required this.valueEth,
    required this.iconName,
  });

  final String title;
  final String subtitle;
  final double valueEth;
  final String iconName;

  factory MarketActivity.fromMap(Map<String, dynamic> map) {
    return MarketActivity(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      valueEth: _toDouble(map['value_eth']),
      iconName: map['icon_name'] as String? ?? 'sell',
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
