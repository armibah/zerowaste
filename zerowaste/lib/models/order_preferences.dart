class OrderPreferences {
  const OrderPreferences({
    required this.defaultAddress,
    required this.deliveryNotes,
    required this.preferPlasticFreePackaging,
    required this.allowSubstitutions,
    required this.carbonNeutralShipping,
  });

  final String defaultAddress;
  final String deliveryNotes;
  final bool preferPlasticFreePackaging;
  final bool allowSubstitutions;
  final bool carbonNeutralShipping;

  OrderPreferences copyWith({
    String? defaultAddress,
    String? deliveryNotes,
    bool? preferPlasticFreePackaging,
    bool? allowSubstitutions,
    bool? carbonNeutralShipping,
  }) {
    return OrderPreferences(
      defaultAddress: defaultAddress ?? this.defaultAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      preferPlasticFreePackaging:
          preferPlasticFreePackaging ?? this.preferPlasticFreePackaging,
      allowSubstitutions: allowSubstitutions ?? this.allowSubstitutions,
      carbonNeutralShipping:
          carbonNeutralShipping ?? this.carbonNeutralShipping,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'user_id': userId,
      'default_address': defaultAddress,
      'delivery_notes': deliveryNotes,
      'prefer_plastic_free_packaging': preferPlasticFreePackaging,
      'allow_substitutions': allowSubstitutions,
      'carbon_neutral_shipping': carbonNeutralShipping,
    };
  }

  factory OrderPreferences.fromMap(Map<String, dynamic> map) {
    return OrderPreferences(
      defaultAddress: map['default_address'] as String? ?? '',
      deliveryNotes: map['delivery_notes'] as String? ?? '',
      preferPlasticFreePackaging:
          map['prefer_plastic_free_packaging'] as bool? ?? true,
      allowSubstitutions: map['allow_substitutions'] as bool? ?? true,
      carbonNeutralShipping: map['carbon_neutral_shipping'] as bool? ?? true,
    );
  }
}
