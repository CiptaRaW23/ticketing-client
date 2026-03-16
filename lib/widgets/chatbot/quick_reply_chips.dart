// widgets/chatbot/quick_reply_chips.dart

import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

class QuickReplyChips extends StatelessWidget {
  final List<QuickReply> suggestions;
  final void Function(String query) onTap;

  const QuickReplyChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final s = suggestions[i];
          return GestureDetector(
            onTap: () => onTap(s.query),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCFD8DC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF37474F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
