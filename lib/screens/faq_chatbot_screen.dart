// screens/faq_chatbot_screen.dart

import 'package:flutter/material.dart';
import 'chatbot_service.dart';

class FaqChatbotScreen extends StatefulWidget {
  const FaqChatbotScreen({super.key});

  @override
  State<FaqChatbotScreen> createState() => _FaqChatbotScreenState();
}

class _FaqChatbotScreenState extends State<FaqChatbotScreen> {
  static final ChatbotService _chatbot = ChatbotService();
  static bool _chatbotReady = false;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;

  final List<_QuickReply> _suggestions = const [
    _QuickReply(
      emoji: '🐌',
      label: 'Internet Lemot',
      query: 'internet saya lemot banget',
    ),
    _QuickReply(
      emoji: '❌',
      label: 'Tidak Konek',
      query: 'internet mati tidak bisa connect',
    ),
    _QuickReply(
      emoji: '⚠️',
      label: 'Putus-Putus',
      query: 'koneksi sering putus putus',
    ),
    _QuickReply(
      emoji: '🔴',
      label: 'LOS Merah',
      query: 'lampu los modem merah',
    ),
    _QuickReply(
      emoji: '📶',
      label: 'WiFi Hilang',
      query: 'sinyal wifi tidak muncul',
    ),
    _QuickReply(
      emoji: '🔄',
      label: 'Restart Stuck',
      query: 'sudah restart tapi tidak ngefek',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      setState(() => _hasText = _inputController.text.trim().isNotEmpty);
    });
    _initBot();
  }

  Future<void> _initBot() async {
    if (_chatbotReady) {
      if (_messages.isEmpty) _addWelcomeMessage();
      return;
    }
    setState(() => _isThinking = true);
    try {
      await _chatbot.initialize();
      _chatbotReady = true;
      _addWelcomeMessage();
    } catch (e) {
      _addBotMessage(
        '❌ Gagal memuat model chatbot.\n\nSilakan hubungi CS kami:\n'
        '📞 021-5055-5100\n💬 WA: 0811-9999-123',
      );
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  void _addWelcomeMessage() {
    _addBotMessage(
      '👋 Halo! Saya asisten virtual FirstMedia.\n\n'
      'Saya bisa membantu keluhan seperti:\n'
      '• 🐌 Internet lemot\n'
      '• ⚠️ Koneksi putus-putus\n'
      '• ❌ Internet mati total\n'
      '• 🔴 Lampu modem merah (LOS)\n'
      '• 📶 WiFi hilang\n'
      '• 🔧 Gangguan jaringan\n\n'
      'Ketik keluhan Anda atau pilih topik di bawah!',
    );
  }

  void _addBotMessage(String text, {double? confidence}) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: false, confidence: confidence),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isThinking) return;

    _inputController.clear();
    _addUserMessage(trimmed);
    setState(() => _isThinking = true);

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final result = await _chatbot.getResponseWithConfidence(trimmed);
      _addBotMessage(
        result['response'] as String,
        confidence: result['confidence'] as double?,
      );
    } catch (e) {
      _addBotMessage(
        'Terjadi kesalahan. Silakan coba lagi atau hubungi CS di 021-5055-5100.',
      );
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && _isThinking
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    itemCount: _messages.length + (_isThinking ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (_isThinking && i == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(message: _messages[i]);
                    },
                  ),
          ),

          // ── Quick reply chips ──
          if (!_isThinking)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final s = _suggestions[i];
                  return GestureDetector(
                    onTap: () => _sendMessage(s.query),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
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
            ),

          const SizedBox(height: 6),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leadingWidth: 56,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: CircleAvatar(
          backgroundColor: Colors.white24,
          child: Text(
            'FM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FirstMedia Support', style: TextStyle(fontSize: 15)),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _chatbotReady ? Colors.greenAccent : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _chatbotReady ? 'Online' : 'Memuat...',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Mulai chat baru',
            onPressed: _confirmReset,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: !_isThinking,
                onSubmitted: _sendMessage,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: Color(0xFF263238)),
                decoration: InputDecoration(
                  hintText: _isThinking
                      ? 'Sedang memproses...'
                      : 'Ketik keluhan Anda...',
                  hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: _hasText && !_isThinking
                    ? Colors.blue
                    : const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => _sendMessage(_inputController.text),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: _hasText && !_isThinking
                          ? Colors.white
                          : const Color(0xFFB0BEC5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Chat Baru?'),
        content: const Text('Riwayat chat akan dihapus.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _messages.clear());
              _addWelcomeMessage();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final double? confidence;
  final DateTime timestamp;

  _ChatMessage({required this.text, required this.isUser, this.confidence})
    : timestamp = DateTime.now();

  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _QuickReply {
  final String emoji;
  final String label;
  final String query;
  const _QuickReply({
    required this.emoji,
    required this.label,
    required this.query,
  });
}

// ── Chat Bubble ────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_BotAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 3),
                      bottomRight: Radius.circular(isUser ? 3 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFEEF2F7)),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF263238),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                // Timestamp + confidence badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timeString,
                      style: const TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 10,
                      ),
                    ),
                    // Badge confidence — hanya untuk pesan bot yang punya nilai
                    if (!isUser && message.confidence != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _confidenceColor(
                            message.confidence!,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(message.confidence! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _confidenceColor(message.confidence!),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Color _confidenceColor(double c) {
    if (c >= 0.7) return Colors.green;
    if (c >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'FM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Typing Indicator ───────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );
    _animations = List.generate(3, (i) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].forward();
      });
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFEEF2F7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
