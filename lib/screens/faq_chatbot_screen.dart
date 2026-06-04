// screens/faq_chatbot_screen.dart

import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../models/chat_message.dart';
import '../widgets/chatbot/chat_bubble.dart';
import '../widgets/chatbot/typing_indicator.dart';
import '../widgets/chatbot/quick_reply_chips.dart';
import 'tickets_screen.dart'; // ← navigasi ke TicketsScreen

class FaqChatbotScreen extends StatefulWidget {
  const FaqChatbotScreen({super.key});

  @override
  State<FaqChatbotScreen> createState() => _FaqChatbotScreenState();
}

class _FaqChatbotScreenState extends State<FaqChatbotScreen>
    with WidgetsBindingObserver {
  final _chatbot = ChatbotService.instance;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isThinking = false;
  bool _hasText = false;

  // ── Quick reply chips ─────────────────────────────────────
  static const _suggestions = [
    QuickReply(
      emoji: '🐌',
      label: 'Internet Lemot',
      query: 'internet saya lemot banget',
    ),
    QuickReply(
      emoji: '❌',
      label: 'Tidak Konek',
      query: 'internet mati tidak bisa connect',
    ),
    QuickReply(
      emoji: '⚠️',
      label: 'Putus-Putus',
      query: 'koneksi sering putus putus',
    ),
    QuickReply(emoji: '🔴', label: 'LOS Merah', query: 'lampu los modem merah'),
    QuickReply(
      emoji: '📶',
      label: 'WiFi Hilang',
      query: 'sinyal wifi tidak muncul',
    ),
    QuickReply(
      emoji: '🔄',
      label: 'Restart Stuck',
      query: 'sudah restart tapi tidak ngefek',
    ),
  ];

  // ─────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _initBot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // Scroll naik saat keyboard muncul supaya pesan terakhir tetap kelihatan
  @override
  void didChangeMetrics() {
    final bottom = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottom > 0) _scrollToBottom(delay: 300);
  }

  // ─────────────────────────────────────────────────────────
  // Inisialisasi
  // ─────────────────────────────────────────────────────────
  Future<void> _initBot() async {
    if (_chatbot.isInitialized) {
      if (_messages.isEmpty) _addWelcomeMessage();
      return;
    }
    setState(() => _isThinking = true);
    try {
      await _chatbot.initialize();
    } catch (_) {
      _addSingleBotMsg(
        '❌ Gagal memuat chatbot. Coba tutup dan buka kembali aplikasi 🙏',
      );
    } finally {
      if (mounted) setState(() => _isThinking = false);
      if (_messages.isEmpty) _addWelcomeMessage();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Pesan selamat datang — singkat & conversational
  // ─────────────────────────────────────────────────────────
  void _addWelcomeMessage() {
    _addSingleBotMsg(
      '👋 Halo! Saya asisten virtual Jagonet.\n\n'
      'Ceritakan masalah internet kamu — saya siap bantu! '
      'Atau pilih topik di bawah ya 👇',
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helpers tambah pesan
  // ─────────────────────────────────────────────────────────
  void _addUserMsg(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: text, type: MessageType.user));
    });
    _scrollToBottom();
  }

  void _addSingleBotMsg(
    String text, {
    double? confidence,
    String? predictedClass,
  }) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          type: MessageType.bot,
          confidence: confidence,
          predictedClass: predictedClass,
          isDefault: predictedClass == null || predictedClass == 'default',
        ),
      );
    });
    _scrollToBottom();
  }

  // ─────────────────────────────────────────────────────────
  // Kirim pesan + respons multi-bubble bertahap
  // ─────────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isThinking) return;

    _inputCtrl.clear();
    _addUserMsg(trimmed);
    setState(() => _isThinking = true);

    // Jeda kecil sebelum mulai "mengetik"
    await _delay(400);

    try {
      final result = await _chatbot.predict(trimmed);
      final bubbles = result.bubbles;

      for (int i = 0; i < bubbles.length; i++) {
        final isLast = i == bubbles.length - 1;

        // Typing indicator muncul
        // (sudah ditampilkan via _isThinking = true + TypingIndicator di build)
        // Jeda simulasi typing — lebih panjang untuk bubble yang lebih panjang
        final typingMs = _typingDelay(bubbles[i].length);
        await _delay(typingMs);

        if (!mounted) break;

        // Tambahkan bubble ke list
        final msg = ChatMessage(
          text: bubbles[i],
          type: MessageType.bot,
          confidence: isLast ? result.confidence : null,
          predictedClass: result.predictedClass,
          isDefault: result.isDefault,
          // CTA tiket hanya di bubble terakhir dan hanya untuk kelas yang perlu eskalasi
          showTicketCta: isLast && result.shouldShowTicketCta,
        );
        setState(() => _messages.add(msg));
        _scrollToBottom();

        // Jeda antar bubble (kecuali bubble terakhir)
        if (!isLast) await _delay(500);
      }
    } catch (_) {
      if (mounted) {
        _addSingleBotMsg('Maaf, terjadi kesalahan. Silakan coba lagi ya 🙏');
      }
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  // Hitung delay typing berdasarkan panjang teks (min 600ms, max 1800ms)
  int _typingDelay(int charCount) {
    return (600 + (charCount * 10)).clamp(600, 1800);
  }

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _scrollToBottom({int delay = 100}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // Feedback: 👍 / 👎
  // ─────────────────────────────────────────────────────────
  void _handleFeedback(ChatMessage msg, bool liked) {
    final idx = _messages.indexOf(msg);
    if (idx < 0) return;
    setState(() {
      _messages[idx].feedback = liked;
    });

    // Kalau tidak membantu dan belum ada CTA tiket, tampilkan CTA
    if (!liked && !_messages[idx].showTicketCta) {
      setState(() => _messages[idx].showTicketCta = true);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Reset / chat baru
  // ─────────────────────────────────────────────────────────
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Mulai chat baru?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Riwayat percakapan akan dihapus.',
          style: TextStyle(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _messages.clear());
              _addWelcomeMessage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildChipsAndInput(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      foregroundColor: Colors.white,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.15),
          child: const Text(
            'J',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jagonet Support',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _chatbot.isInitialized
                      ? Colors.greenAccent
                      : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _chatbot.isInitialized ? 'Online' : 'Memuat...',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.length > 1)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Mulai chat baru',
            onPressed: _confirmReset,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Daftar pesan ─────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      itemCount: _messages.length + (_isThinking ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (_isThinking && i == _messages.length) {
          return const TypingIndicator();
        }
        return _AnimatedMessageItem(
          key: ValueKey(_messages[i].id),
          child: ChatBubble(
            message: _messages[i],
            onFeedback: _handleFeedback,
            onTicketTap: () => _onTicketTap(_messages[i]),
          ),
        );
      },
    );
  }

  // ── Chips + Input ─────────────────────────────────────────
  Widget _buildChipsAndInput() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chips hanya tampil kalau bot tidak sedang mengetik
          if (!_isThinking) ...[
            const SizedBox(height: 10),
            QuickReplyChips(suggestions: _suggestions, onTap: _sendMessage),
            const SizedBox(height: 8),
          ],
          _buildInputRow(),
          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 4 : 8),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 42, maxHeight: 110),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _inputFocus.hasFocus
                      ? const Color(0xFF81C784) // hijau muda saat fokus
                      : const Color(0xFFDDE4EC),
                ),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                enabled: !_isThinking,
                onSubmitted: (v) => _sendMessage(v),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C2B3A),
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _isThinking
                      ? 'Sedang memproses...'
                      : 'Ketik keluhan Anda...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Tombol kirim
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (_hasText && !_isThinking)
                  ? Colors.green
                  : const Color(0xFFECF0F5),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_hasText && !_isThinking)
                    ? () => _sendMessage(_inputCtrl.text)
                    : null,
                borderRadius: BorderRadius.circular(21),
                child: Center(
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: (_hasText && !_isThinking)
                        ? Colors.white
                        : const Color(0xFFB0BEC5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Aksi tiket — navigasi ke TicketsScreen dengan pre-fill hint
  // ─────────────────────────────────────────────────────────
  void _onTicketTap(ChatMessage msg) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TicketsScreen()),
    ).then((_) {
      // Setelah kembali dari TicketsScreen, tidak perlu reload apa-apa
      // karena chatbot tidak punya state tiket sendiri.
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper animasi untuk setiap item pesan (fade + slide dari bawah)
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  const _AnimatedMessageItem({super.key, required this.child});

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
