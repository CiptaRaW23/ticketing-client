import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final Ticket ticket;

  const ChatScreen({super.key, required this.ticket});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List<dynamic> messages = [];
  final SocketService _socketService = SocketService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    messages = widget.ticket.messages ?? [];
    _socketService.joinRoom(widget.ticket.id);
    _socketService.onNewMessage((data) {
      if (mounted) {
        setState(() {
          messages.add(data);
        });
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    _socketService.sendMessage(widget.ticket.id, text);
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isSending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Ticket #${widget.ticket.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // bisa tambah refresh dari API kalau perlu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Belum ada pesan. Mulai chat!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg['sender'] == 'customer';
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['message'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                DateTime.parse(
                                  msg['createdAt'],
                                ).toLocal().toString().substring(11, 16),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                _isSending
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : FloatingActionButton(
                        mini: true,
                        onPressed: _sendMessage,
                        child: const Icon(Icons.send),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // optional leave room
    super.dispose();
  }
}
