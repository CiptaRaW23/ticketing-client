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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (ctx, i) {
          final s = suggestions[i];
          return _Chip(suggestion: s, onTap: () => onTap(s.query));
        },
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  final QuickReply suggestion;
  final VoidCallback onTap;
  const _Chip({required this.suggestion, required this.onTap});

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed ? const Color(0xFFA5D6A7) : const Color(0xFFDDE4EC),
          ),
          boxShadow: _pressed
              ? []
              : [
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
            Text(widget.suggestion.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              widget.suggestion.label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
