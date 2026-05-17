// screens/tickets_screen.dart
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

    _socket.init();

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

  List<Ticket> get _filteredTickets {
    switch (_filterStatus) {
      case 'active':
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

    // [FIX 8] State untuk counter karakter dan validasi
    int titleLen = 0;
    int descLen = 0;
    bool isSubmitting = false;

    const int minTitle = 10;
    const int minDesc = 30;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Update counter saat teks berubah
          titleCtrl.addListener(() {
            setModalState(() => titleLen = titleCtrl.text.length);
          });
          descCtrl.addListener(() {
            setModalState(() => descLen = descCtrl.text.length);
          });

          final isTitleValid = titleLen >= minTitle;
          final isDescValid = descLen >= minDesc;

          return Padding(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // [FIX 8] Judul dengan counter karakter
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Keluhan *',
                    border: const OutlineInputBorder(),
                    hintText: 'Contoh: Internet tidak bisa konek',
                    // Counter dan pesan error
                    counterText: '$titleLen karakter',
                    errorText: titleLen > 0 && !isTitleValid
                        ? 'Minimal $minTitle karakter (kurang ${minTitle - titleLen})'
                        : null,
                    suffixIcon: isTitleValid
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),

                // [FIX 8] Deskripsi dengan counter karakter
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Keluhan *',
                    border: const OutlineInputBorder(),
                    hintText: 'Jelaskan masalah yang Anda alami...',
                    alignLabelWithHint: true,
                    counterText: '$descLen karakter',
                    errorText: descLen > 0 && !isDescValid
                        ? 'Minimal $minDesc karakter (kurang ${minDesc - descLen})'
                        : null,
                    suffixIcon: isDescValid
                        ? const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {},
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
                    // [FIX 8] Tombol hanya aktif jika validasi lolos
                    onPressed: (isSubmitting || !isTitleValid || !isDescValid)
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            final address = addressCtrl.text.trim().isEmpty
                                ? null
                                : addressCtrl.text.trim();

                            setModalState(() => isSubmitting = true);
                            try {
                              final newTicket = await _api.createTicket(
                                title,
                                desc,
                                address: address,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                setState(() {
                                  _tickets.insert(0, newTicket);
                                });
                                // [FIX 1] Ganti SnackBar dengan dialog konfirmasi
                                _showTicketSuccessDialog(newTicket);
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
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
          );
        },
      ),
    );
  }

  // [FIX 1] Dialog konfirmasi setelah ticket berhasil dibuat
  void _showTicketSuccessDialog(Ticket newTicket) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green[700],
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keluhan Berhasil Dikirim!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tim kami akan segera menindaklanjuti keluhanmu.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Tampilkan ID ticket dengan jelas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tag, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Nomor Ticket: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text(
                    '${newTicket.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Catat nomor ini untuk referensi',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(
            children: [
              // Langsung buka chat ticket
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openChat(newTicket);
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Buka Chat Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Kembali ke daftar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Kembali ke Daftar Ticket',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(Ticket ticket) async {
    try {
      final fresh = await _api.getTicketDetail(ticket.id);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(ticket: fresh)),
      );
      _loadTickets();
    } catch (e) {
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
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socket.removeListeners();
    super.dispose();
  }
}
