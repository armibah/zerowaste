class OrderSettings {
  const OrderSettings({
    required this.plasticFreePackaging,
    required this.contactlessDelivery,
    required this.refillReminders,
    required this.preferredDeliveryWindow,
    required this.deliveryNotes,
  });

  final bool plasticFreePackaging;
  final bool contactlessDelivery;
  final bool refillReminders;
  final String preferredDeliveryWindow;
  final String deliveryNotes;

  factory OrderSettings.defaults() {
    return const OrderSettings(
      plasticFreePackaging: true,
      contactlessDelivery: false,
      refillReminders: true,
      preferredDeliveryWindow: 'Morning',
      deliveryNotes: '',
    );
  }

  factory OrderSettings.fromMap(Map<String, dynamic> map) {
    return OrderSettings(
      plasticFreePackaging: map['plastic_free_packaging'] as bool? ?? true,
      contactlessDelivery: map['contactless_delivery'] as bool? ?? false,
      refillReminders: map['refill_reminders'] as bool? ?? true,
      preferredDeliveryWindow:
          map['preferred_delivery_window'] as String? ?? 'Morning',
      deliveryNotes: map['delivery_notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plastic_free_packaging': plasticFreePackaging,
      'contactless_delivery': contactlessDelivery,
      'refill_reminders': refillReminders,
      'preferred_delivery_window': preferredDeliveryWindow,
      'delivery_notes': deliveryNotes,
    };
  }
}
