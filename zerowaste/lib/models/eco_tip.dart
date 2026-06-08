class EcoTip {
  const EcoTip({
    required this.id,
    required this.title,
    required this.body,
    required this.iconName,
  });

  final String id;
  final String title;
  final String body;
  final String iconName;

  factory EcoTip.fromMap(Map<String, dynamic> map) {
    return EcoTip(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'eco',
    );
  }
}