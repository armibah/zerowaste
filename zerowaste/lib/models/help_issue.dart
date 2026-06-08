class HelpIssue {
  const HelpIssue({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final String body;
  final String status;
  final DateTime createdAt;

  factory HelpIssue.fromMap(Map<String, dynamic> map) {
    return HelpIssue(
      id: map['id'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      body: map['body'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
