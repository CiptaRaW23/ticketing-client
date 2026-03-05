// screens/tickets_screen.dart
// FIXED:
// - Socket init() dipanggil sekali, dispose() TIDAK dipanggil (singleton)
// - Filter 'open' logic diperbaiki — tampilkan open & in-progress di tab "Aktif"
// - createTicket() return Ticket — bisa langsung tambah ke list tanpa reload
// - Error message pakai ApiService.errorMessage()
// - Tampilkan badge jumlah ticket aktif di AppBar
// - Pull-to-refresh benar
// - TicketCard navigasi ke ChatScreen dengan data fresh dari API

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
  List<Ticket> _tickets = [];
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  bool _isLoading = false;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadTickets();

    // FIXED: init socket jika belum (singleton, aman dipanggil berulang)
    _socket.init();

    // FIXED: pakai onTicketUpdated bukan onTicketUpdate (nama konsisten dengan SocketService)
    _socket.onTicketUpdated((_) {
      if (mounted) _loadTickets();
    });

    _socket.onNewTicket((_) {
      if (mounted) _loadTickets();
    });
  }

  Future<void> _loadTickets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loaded = await _api.getTickets();
      if (mounted) {
        setState(() {
          // Urutkan: open & in-progress dulu, lalu closed, terbaru di atas
          _tickets = loaded
            ..sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return b.createdAt.compareTo(a.createdAt);
            });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat ticket: ${ApiService.errorMessage(e)}'),
          ),
        );
      }
    }
  }

  // FIXED: filter logic yang benar
  List<Ticket> get _filteredTickets {
    switch (_filterStatus) {
      case 'active':
        // "Aktif" = open + in-progress
        return _tickets
            .where((t) => t.status == 'open' || t.status == 'in-progress')
            .toList();
      case 'closed':
        return _tickets.where((t) => t.status == 'closed').toList();
      default:
        return _tickets;
    }
  }

  int get _activeCount => _tickets.where((t) => t.isActive).length;

  void _showSubmitTicketDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Keluhan Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Keluhan *',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Internet tidak bisa konek',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Keluhan *',
                  border: OutlineInputBorder(),
                  hintText: 'Jelaskan masalah yang Anda alami...',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat (opsional)',
                  border: OutlineInputBorder(),
                  hintText: 'Kosongkan jika alamat sudah terdaftar',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final desc = descCtrl.text.trim();
                          final address = addressCtrl.text.trim().isEmpty
                              ? null
                              : addressCtrl.text.trim();

                          if (title.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Judul dan deskripsi wajib diisi',
                                ),
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            // FIXED: createTicket sekarang return Ticket
                            final newTicket = await _api.createTicket(
                              title,
                              desc,
                              address: address,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              setState(() {
                                _tickets.insert(
                                  0,
                                  newTicket,
                                ); // tambah langsung ke list
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Keluhan berhasil dikirim!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal kirim: ${ApiService.errorMessage(e)}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Keluhan',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(Ticket ticket) async {
    // FIXED: Ambil data fresh dari API sebelum buka chat (pastikan messages terbaru)
    try {
      final fresh = await _api.getTicketDetail(ticket.id);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(ticket: fresh)),
      );
      _loadTickets(); // refresh setelah kembali
    } catch (e) {
      // Fallback: pakai data lokal jika API gagal
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(ticket: ticket)),
      );
      _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Riwayat Ticket'),
            if (_activeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_activeCount aktif',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTickets),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai', 'closed'),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'all'
                              ? 'Belum ada ticket.\nTekan + untuk buat keluhan baru.'
                              : 'Tidak ada ticket ${_filterStatus == 'active' ? 'aktif' : 'selesai'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTickets,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 90),
                      itemCount: _filteredTickets.length,
                      itemBuilder: (ctx, i) => TicketCard(
                        ticket: _filteredTickets[i],
                        onTap: () => _openChat(_filteredTickets[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitTicketDialog,
        icon: const Icon(Icons.add),
        label: const Text('Keluhan Baru'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterStatus = value),
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  @override
  void dispose() {
    // FIXED: JANGAN dispose() socket singleton di sini!
    // Cukup hapus listener yang relevan dengan screen ini
    _socket.removeListeners();
    super.dispose();
  }
}
