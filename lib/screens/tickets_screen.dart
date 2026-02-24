import 'package:flutter/material.dart';
import '../widgets/ticket_card.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/ticket.dart';
import 'chat_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<Ticket> tickets = [];
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  bool _isLoading = false;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _socketService.init();
    _socketService.onTicketUpdate(() => _loadTickets());
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final loadedTickets = await _apiService.getTickets();
      setState(() {
        tickets = loadedTickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal load ticket: $e')));
      }
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Keluhan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Keluhan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat (opsional)',
                  hintText: 'Kosongkan kalau sudah terdaftar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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

              if (title.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Judul dan deskripsi wajib diisi'),
                  ),
                );
                return;
              }

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
    ).then((_) => _loadTickets());
  }

  List<Ticket> get _filteredTickets {
    if (_filterStatus == 'all') return tickets;
    if (_filterStatus == 'open') {
      return tickets.where((t) => t.status != 'closed').toList();
    }
    return tickets.where((t) => t.status == 'closed').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Ticket'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTickets),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif', 'open'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai', 'closed'),
              ],
            ),
          ),

          // List Tickets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'all'
                              ? 'Belum ada ticket'
                              : 'Tidak ada ticket ${_filterStatus == 'open' ? 'aktif' : 'selesai'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTickets,
                    child: ListView.builder(
                      itemCount: _filteredTickets.length,
                      itemBuilder: (ctx, i) {
                        return TicketCard(
                          ticket: _filteredTickets[i],
                          onTap: () => _openChat(_filteredTickets[i]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitTicket,
        icon: const Icon(Icons.add),
        label: const Text('Keluhan Baru'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
        },
        selectedColor: Colors.blue,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
