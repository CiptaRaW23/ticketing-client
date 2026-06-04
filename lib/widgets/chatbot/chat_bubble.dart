// widgets/chatbot/chat_bubble.dart

import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Konstanta warna & radius — selaras dengan TicketsScreen (hijau)
// ─────────────────────────────────────────────────────────────────────────────
const _kColorUser = Colors.green; // hijau — bubble user
const _kColorUserText = Colors.white;
const _kColorBot = Color(0xFFFFFFFF); // putih — bubble bot
const _kColorBotBorder = Color(0xFFE4EDE4);
const _kColorBotText = Color(0xFF1C2B3A);
const _kColorMeta = Color(0xFFB0BEC5);
const _kColorFeedbackActive = Colors.green;
const _kColorFeedbackBg = Color(0xFFF0FFF4); // hijau sangat muda
const _kColorTicketBg = Color(0xFFF0FFF4);
const _kColorTicketBorder = Color(0xFFA5D6A7);
const _kColorTicketText = Color(0xFF2E7D32); // hijau gelap
const _kColorConfidenceHigh = Color(0xFF2E7D32);
const _kColorConfidenceMid = Color(0xFFE65100);

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  /// Dipanggil saat user tap 👍/👎
  final void Function(ChatMessage msg, bool liked)? onFeedback;

  /// Dipanggil saat user tap "Buat Tiket"
  final VoidCallback? onTicketTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onFeedback,
    this.onTicketTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[const _BotAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // ── Bubble utama ──────────────────────────────────────────
                _BubbleBody(message: message, isUser: isUser),

                const SizedBox(height: 4),

                // ── Meta: waktu + badge confidence ───────────────────────
                _MetaRow(message: message, isUser: isUser),

                // ── Feedback & tiket (hanya bubble bot) ──────────────────
                if (!isUser) ...[
                  const SizedBox(height: 6),
                  _BotActions(
                    message: message,
                    onFeedback: onFeedback,
                    onTicketTap: onTicketTap,
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble body
// ─────────────────────────────────────────────────────────────────────────────
class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  const _BubbleBody({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? _kColorUser : _kColorBot,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser ? null : Border.all(color: _kColorBotBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isUser ? _kColorUserText : _kColorBotText,
          fontSize: 14,
          height: 1.55,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta row: waktu + badge confidence
// ─────────────────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  const _MetaRow({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final label = message.confidenceLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeString,
          style: const TextStyle(color: _kColorMeta, fontSize: 10),
        ),
        if (!isUser && label != null) ...[
          const SizedBox(width: 5),
          _ConfidenceBadge(label: label, confidence: message.confidence!),
        ],
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String label;
  final double confidence;
  const _ConfidenceBadge({required this.label, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final isHigh = confidence >= 0.70;
    final color = isHigh ? _kColorConfidenceHigh : _kColorConfidenceMid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHigh
                ? Icons.check_circle_outline_rounded
                : Icons.help_outline_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aksi bawah bubble bot: feedback + tiket
// ─────────────────────────────────────────────────────────────────────────────
class _BotActions extends StatelessWidget {
  final ChatMessage message;
  final void Function(ChatMessage, bool)? onFeedback;
  final VoidCallback? onTicketTap;
  const _BotActions({required this.message, this.onFeedback, this.onTicketTap});

  @override
  Widget build(BuildContext context) {
    // Tidak tampilkan feedback jika ini bukan pesan "berisi solusi"
    final showFeedback = !message.isDefault && message.confidence != null;
    final showTicket = message.showTicketCta;

    if (!showFeedback && !showTicket) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFeedback)
          _FeedbackRow(message: message, onFeedback: onFeedback),
        if (showTicket) ...[
          const SizedBox(height: 6),
          _TicketCta(onTap: onTicketTap),
        ],
      ],
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  final ChatMessage message;
  final void Function(ChatMessage, bool)? onFeedback;
  const _FeedbackRow({required this.message, this.onFeedback});

  @override
  Widget build(BuildContext context) {
    final hasVoted = message.feedback != null;

    if (hasVoted) {
      return Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          message.feedback == true
              ? 'Senang bisa membantu! 😊'
              : 'Terima kasih, akan kami catat 🙏',
          style: const TextStyle(fontSize: 11, color: _kColorMeta),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Membantu?',
          style: TextStyle(fontSize: 11, color: _kColorMeta),
        ),
        const SizedBox(width: 6),
        _FeedbackBtn(
          icon: Icons.thumb_up_outlined,
          label: 'Ya',
          onTap: () => onFeedback?.call(message, true),
        ),
        const SizedBox(width: 4),
        _FeedbackBtn(
          icon: Icons.thumb_down_outlined,
          label: 'Tidak',
          onTap: () => onFeedback?.call(message, false),
        ),
      ],
    );
  }
}

class _FeedbackBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeedbackBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _kColorFeedbackBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _kColorFeedbackActive),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _kColorFeedbackActive,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCta extends StatelessWidget {
  final VoidCallback? onTap;
  const _TicketCta({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _kColorTicketBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kColorTicketBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 15,
              color: _kColorTicketText,
            ),
            const SizedBox(width: 7),
            const Text(
              'Buat Tiket Laporan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kColorTicketText,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: _kColorTicketText,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar bot
// ─────────────────────────────────────────────────────────────────────────────
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key});

  @override
  Widget build(BuildContext context) => const _BotAvatar();
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Text(
          'J',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
