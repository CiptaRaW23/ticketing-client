import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ticket_card.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/ticket.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ticket> tickets = [];
  String userName = 'Customer';
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTickets();
    _socketService.init();
    _socketService.onTicketUpdate(() => _loadTickets());
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Customer';
    });
  }

  Future<void> _loadTickets() async {
    try {
      final loadedTickets = await _apiService.getTickets();
      setState(() {
        tickets = loadedTickets;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal load ticket: $e')));
    }
  }

  void _showSubmitTicket() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Keluhan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Keluhan'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Deskripsi Keluhan'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat (opsional)',
                hintText: 'Kosongkan kalau sudah terdaftar',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              final address = addressController.text.trim().isEmpty
                  ? null
                  : addressController.text.trim();

              if (title.isEmpty || desc.isEmpty) return;

              try {
                await _apiService.createTicket(title, desc, address: address);
                Navigator.pop(ctx);
                _loadTickets();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keluhan berhasil dikirim!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal kirim: $e')));
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _openChat(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(ticket: ticket)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, $userName'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTickets),
        ],
      ),
      body: tickets.isEmpty
          ? const Center(child: Text('Belum ada ticket'))
          : ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (ctx, i) {
                return TicketCard(
                  ticket: tickets[i],
                  onTap: () => _openChat(tickets[i]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSubmitTicket,
        child: const Icon(Icons.add),
        tooltip: 'Keluhan Baru',
      ),
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
