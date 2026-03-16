// models/chat_message.dart

class ChatMessage {
  final String text;
  final bool isUser;
  final double? confidence;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, this.confidence})
    : timestamp = DateTime.now();

  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

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
