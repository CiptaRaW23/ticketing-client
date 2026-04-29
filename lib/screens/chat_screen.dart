import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Ticket ticket;

  const ChatScreen({super.key, required this.ticket});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final SocketService _socket = SocketService();
  final ApiService _api = ApiService();

  late List<dynamic> _messages;
  bool _isSending = false;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.ticket.messages);
    _isClosed = widget.ticket.status == 'closed';

    _socket.joinRoom(widget.ticket.id);
    _socket.onNewMessage(_onNewMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onNewMessage(dynamic data) {
    if (!mounted) return;
    final msgData = data as Map<String, dynamic>? ?? {};
    final incomingId = msgData['id'];
    final incomingSender = msgData['sender'];

    setState(() {
      final optimisticIndex = _messages.indexWhere(
        (m) =>
            m is Map &&
            m['_optimistic'] == true &&
            m['sender'] == incomingSender,
      );

      if (optimisticIndex != -1) {
        _messages[optimisticIndex] = msgData;
      } else {
        final alreadyExists =
            incomingId != null &&
            _messages.any((m) => m is Map && m['id'] == incomingId);
        if (!alreadyExists) {
          _messages.add(msgData);
        }
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _isClosed) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final optimisticMsg = {
      'message': text,
      'sender': 'customer',
      'createdAt': DateTime.now().toIso8601String(),
      '_optimistic': true,
    };
    setState(() => _messages.add(optimisticMsg));
    _scrollToBottom();

    if (_socket.isConnected) {
      _socket.sendMessage(widget.ticket.id, text);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Koneksi real-time terputus. Pesan mungkin tidak terkirim.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isSending = false);
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      return DateTime.parse(isoString).toLocal().toString().substring(11, 16);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket #${widget.ticket.id}',
              style: const TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                _statusDot(widget.ticket.status),
                const SizedBox(width: 4),
                Text(
                  widget.ticket.statusLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showTicketInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner kalau sudah closed ──
          if (_isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Ticket ini sudah selesai. Chat hanya baca.',
                    style: TextStyle(color: Colors.green[700], fontSize: 13),
                  ),
                ],
              ),
            ),

          // ── Daftar pesan ──
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pesan.\nMulai sampaikan keluhanmu!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
                  ),
          ),

          // ── Input area ──
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(dynamic msg) {
    if (msg is! Map) return const SizedBox.shrink();

    final sender = msg['sender'] as String? ?? 'unknown';
    final text = msg['message'] as String? ?? '';
    final createdAt = msg['createdAt'] as String?;
    final isMe = sender == 'customer';
    final isBot = sender == 'bot';
    final isOptimistic = msg['_optimistic'] == true;

    final senderLabels = {
      'customer': 'Kamu',
      'admin': 'Admin',
      'bot': '🤖 Bot',
    };

    Color bubbleColor;
    Color textColor;
    if (isMe) {
      // CHANGED: biru → hijau
      bubbleColor = isOptimistic ? Colors.green[300]! : Colors.green[600]!;
      textColor = Colors.white;
    } else if (isBot) {
      bubbleColor = Colors.amber[100]!;
      textColor = Colors.black87;
    } else {
      bubbleColor = Colors.grey[200]!;
      textColor = Colors.black87;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 3),
            bottomRight: Radius.circular(isMe ? 3 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderLabels[sender] ?? sender,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isBot ? Colors.amber[800] : Colors.grey[600],
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.grey[500],
                  ),
                ),
                if (isMe && isOptimistic) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.access_time, size: 10, color: Colors.white60),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
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
                controller: _messageController,
                enabled: !_isClosed,
                decoration: InputDecoration(
                  hintText: _isClosed
                      ? 'Ticket sudah selesai'
                      : 'Ketik pesan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: _isClosed,
                  fillColor: Colors.grey[100],
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      // CHANGED: biru → hijau
                      color: _isClosed ? Colors.grey : Colors.green,
                    ),
                    onPressed: _isClosed ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      // CHANGED: biru → hijau
                      backgroundColor: _isClosed
                          ? Colors.grey[100]
                          : Colors.green[50],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(String status) {
    Color c;
    switch (status) {
      case 'open':
        c = Colors.orange;
        break;
      case 'in-progress':
        c = Colors.blue[300]!; // tetap biru — ini indikator status
        break;
      case 'closed':
        c = Colors.green;
        break;
      default:
        c = Colors.grey;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  void _showTicketInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Detail Ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            _infoRow(Icons.tag, 'ID', '#${widget.ticket.id}'),
            _infoRow(Icons.title, 'Judul', widget.ticket.title),
            _infoRow(Icons.info_outline, 'Status', widget.ticket.statusLabel),
            _infoRow(
              Icons.flag_outlined,
              'Prioritas',
              widget.ticket.priorityLabel,
            ),
            _infoRow(
              Icons.calendar_today,
              'Dibuat',
              widget.ticket.formattedDate,
            ),
            if (widget.ticket.address != null)
              _infoRow(Icons.location_on, 'Alamat', widget.ticket.address!),
            const SizedBox(height: 8),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.ticket.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CHANGED: biru → hijau
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket.removeListeners();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
