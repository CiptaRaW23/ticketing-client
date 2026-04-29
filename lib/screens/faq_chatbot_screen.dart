import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../models/chat_message.dart';
import '../widgets/chatbot/chat_bubble.dart';
import '../widgets/chatbot/typing_indicator.dart';
import '../widgets/chatbot/quick_reply_chips.dart';

class FaqChatbotScreen extends StatefulWidget {
  const FaqChatbotScreen({super.key});

  @override
  State<FaqChatbotScreen> createState() => _FaqChatbotScreenState();
}

class _FaqChatbotScreenState extends State<FaqChatbotScreen> {
  final ChatbotService _chatbot = ChatbotService.instance;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  final List<ChatMessage> _messages = [];
  bool _isThinking = false;

  final List<QuickReply> _suggestions = const [
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

  @override
  void initState() {
    super.initState();
    _inputController.addListener(
      () => setState(() => _hasText = _inputController.text.trim().isNotEmpty),
    );
    _initBot();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initBot() async {
    if (_chatbot.isInitialized) {
      if (_messages.isEmpty) _addWelcomeMessage();
      return;
    }
    setState(() => _isThinking = true);
    try {
      await _chatbot.initialize();
      _addWelcomeMessage();
    } catch (e) {
      _addBotMessage(
        '❌ Gagal memuat chatbot. Silakan tutup dan buka kembali aplikasi 🙏',
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
        ChatMessage(text: text, isUser: false, confidence: confidence),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
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
      _addBotMessage('Terjadi kesalahan. Silakan coba lagi ya 🙏');
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (!_isThinking) ...[
            QuickReplyChips(suggestions: _suggestions, onTap: _sendMessage),
            const SizedBox(height: 6),
          ],
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && _isThinking) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      itemCount: _messages.length + (_isThinking ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (_isThinking && i == _messages.length) {
          return const TypingIndicator();
        }
        return ChatBubble(message: _messages[i]);
      },
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
            'J',
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
          const Text('Jagonet Support', style: TextStyle(fontSize: 15)),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
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
                  // CHANGED: biru → hijau
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.green),
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
                // CHANGED: biru → hijau
                color: _hasText && !_isThinking
                    ? Colors.green
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
