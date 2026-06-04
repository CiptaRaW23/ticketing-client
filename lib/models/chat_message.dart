enum MessageType {
  /// Pesan user biasa
  user,

  /// Pesan bot
  bot,

  /// Pesan bot yang berisi langkah-langkah
  botSteps,

  /// Placeholder "bot sedang mengetik" — dipakai internal, bukan ditampilkan
  typing,
}

/// Satu bubble percakapan.
class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;

  final double? confidence;
  final String? predictedClass;
  final bool isDefault;
  bool? feedback;
  bool showTicketCta;

  ChatMessage({
    required this.text,
    required this.type,
    this.confidence,
    this.predictedClass,
    this.isDefault = false,
    this.feedback,
    this.showTicketCta = false,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString(),
       timestamp = DateTime.now();

  bool get isUser => type == MessageType.user;
  bool get isBot => type == MessageType.bot || type == MessageType.botSteps;

  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Label confidence yang ramah user
  String? get confidenceLabel {
    if (confidence == null) return null;
    if (confidence! >= 0.70) return 'Yakin';
    if (confidence! >= 0.45) return 'Perlu konfirmasi';
    return null; // di bawah 45%: tidak tampilkan label sama sekali
  }
}

/// Quick reply chip yang muncul di bawah chat.
class QuickReply {
  final String emoji;
  final String label;
  final String query;
  const QuickReply({
    required this.emoji,
    required this.label,
    required this.query,
  });
}
