class HelpIssue {
  const HelpIssue({
    required this.subject,
    required this.message,
    required this.contactEmail,
  });

  final String subject;
  final String message;
  final String contactEmail;

  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'user_id': userId,
      'subject': subject,
      'message': message,
      'contact_email': contactEmail,
      'status': 'open',
    };
  }
}
