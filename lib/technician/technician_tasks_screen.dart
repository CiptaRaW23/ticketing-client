import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import 'technician_detail_screen.dart';
import '../widgets/technician_widgets.dart';

class TechnicianTasksScreen extends StatefulWidget {
  const TechnicianTasksScreen({super.key});

  @override
  State<TechnicianTasksScreen> createState() => _TechnicianTasksScreenState();
}

class _TechnicianTasksScreenState extends State<TechnicianTasksScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _tickets = [];
  String _techName = 'Teknisi';
  late TabController _tabController;

  List<Map<String, dynamic>> get _pending =>
      _tickets.where((t) => t['status'] == 'assigned').toList();
  List<Map<String, dynamic>> get _active =>
      _tickets.where((t) => t['status'] == 'in-progress').toList();
  List<Map<String, dynamic>> get _done =>
      _tickets.where((t) => t['status'] == 'closed').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadName();
    _loadTickets();
    _setupSocket();
  }

  @override
  void dispose() {
    _tabController.dispose();
    SocketService().removeListenersByEvent([
      'newAssignment',
      'ticketUpdated',
      'ticketClosed',
      'confirmationRejected',
    ]);
    super.dispose();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _techName = prefs.getString('userName') ?? 'Teknisi');
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/tickets');
      final raw = data is Map ? (data['tickets'] ?? []) : data;
      if (mounted && raw is List) {
        setState(() => _tickets = raw.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal memuat tiket',
        subtitle: ApiService.errorMessage(e),
        type: SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    SocketService().onNewAssignment((data) {
      if (mounted) {
        _loadTickets();
        // Ambil id ticket dari data socket jika tersedia
        final ticketId = data?['ticketId']?.toString() ?? '';
        showSemanticSnack(
          context,
          'Tugas baru diterima',
          subtitle: ticketId.isNotEmpty
              ? 'Ticket #$ticketId · Segera cek'
              : 'Cek tab Pending',
          type: SnackType.warning,
        );
      }
    });
    SocketService().onTicketUpdatedTechnician((_) {
      if (mounted) _loadTickets();
    });

    SocketService().onTicketClosed((data) {
      if (mounted) {
        _loadTickets();
        showSemanticSnack(
          context,
          'Ticket dikonfirmasi selesai',
          subtitle: 'Admin telah approve pekerjaan kamu 👍',
          type: SnackType.success,
        );
      }
    });

    SocketService().onConfirmationRejected((data) {
      if (mounted) {
        _loadTickets();
        showSemanticSnack(
          context,
          'Admin meminta perbaikan lanjutan',
          subtitle: 'Silakan lanjutkan pengerjaan ticket',
          type: SnackType.warning,
        );
      }
    });
  }

  Future<void> _respond(int ticketId, String action, {String? reason}) async {
    try {
      final body = <String, dynamic>{'action': action};
      if (reason != null && reason.isNotEmpty) body['rejectReason'] = reason;
      await _api.post('/tickets/$ticketId/assignment/respond', body);
      showSemanticSnack(
        context,
        action == 'accept' ? 'Tugas berhasil diterima' : 'Tugas ditolak',
        subtitle: action == 'accept'
            ? 'Status ticket → In Progress'
            : 'Admin akan mendapat notifikasi',
        type: action == 'accept' ? SnackType.success : SnackType.warning,
      );
      _loadTickets();
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal merespons tugas',
        subtitle: ApiService.errorMessage(e),
        type: SnackType.error,
      );
    }
  }

  Future<void> _showFullRejectDialog(int ticketId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tolak Tugas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alasan penolakan (opsional):',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Misal: Sedang tidak bisa ke lokasi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Tolak Tugas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _respond(ticketId, 'reject', reason: ctrl.text.trim());
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: TechColors.gradientAppBar,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        TechAvatar(name: _techName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $_techName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Teknisi Lapangan',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge tugas aktif
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_active.length} Aktif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: 'Pending (${_pending.length})'),
                      Tab(text: 'Aktif (${_active.length})'),
                      Tab(text: 'Selesai (${_done.length})'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const TechLoader()
                : RefreshIndicator(
                    color: TechColors.primary,
                    onRefresh: _loadTickets,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(
                          _pending,
                          showAccReject: true,
                          emptyMsg: 'Belum ada tugas pending',
                          emptySub:
                              'Tugas baru muncul otomatis saat admin assign ke kamu',
                        ),
                        _buildList(
                          _active,
                          showAccReject: false,
                          emptyMsg: 'Tidak ada tugas aktif',
                          emptySub: 'Terima dulu tugas dari tab Pending',
                        ),
                        _buildList(
                          _done,
                          showAccReject: false,
                          emptyMsg: 'Belum ada tugas selesai',
                          emptySub: 'Selesaikan ticket yang sedang aktif',
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> list, {
    required bool showAccReject,
    required String emptyMsg,
    required String emptySub,
  }) {
    if (list.isEmpty) {
      return EmptyState(
        emoji: showAccReject ? '📭' : (_active.isEmpty ? '🔧' : '✅'),
        message: emptyMsg,
        subtitle: emptySub,
        onRefresh: _loadTickets,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final ticket = list[i];
        return _TicketCard(
          ticket: ticket,
          showAccReject: showAccReject,
          onAccept: () => _respond(ticket['id'] as int, 'accept'),
          onReject: () => _showFullRejectDialog(ticket['id'] as int),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TechnicianDetailScreen(ticketId: ticket['id'] as int),
            ),
          ).then((_) => _loadTickets()),
        );
      },
    );
  }
}

// ── Ticket Card ──────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final bool showAccReject;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.showAccReject,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  Color get _prioColor {
    switch (ticket['priority']) {
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.orange[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  String get _prioLabel {
    switch (ticket['priority']) {
      case 'high':
        return 'Prioritas Tinggi';
      case 'medium':
        return 'Prioritas Sedang';
      default:
        return 'Prioritas Rendah';
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ticket['visitSchedule'] as Map<String, dynamic>?;
    final assignments = ticket['assignments'] as List?;
    final adminNote = assignments?.isNotEmpty == true
        ? (assignments!.first as Map<String, dynamic>)['adminNote'] as String?
        : null;
    final createdAt = ticket['createdAt'] as String?;
    final phone = ticket['user']?['phone'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: _prioColor.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _prioColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _prioLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _prioColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${ticket['id']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Badge "Baru" jika dibuat dalam 1 jam terakhir
                  if (createdAt != null) ...[
                    const SizedBox(width: 6),
                    if (DateTime.now()
                            .difference(DateTime.parse(createdAt))
                            .inHours <
                        1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3DE),
                          border: Border.all(
                            color: const Color(0xFF97C459),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B6D11),
                          ),
                        ),
                      ),
                  ],
                  const Spacer(),
                  // Timestamp relatif
                  if (createdAt != null)
                    Text(
                      timeAgo(createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    icon: Icons.person_outline_rounded,
                    text: ticket['user']?['name'] ?? 'Customer',
                  ),
                  if ((ticket['address'] as String?)?.isNotEmpty == true)
                    InfoRow(
                      icon: Icons.location_on_outlined,
                      text: ticket['address'] as String,
                    ),
                  // Nomor HP bisa di-tap langsung telepon
                  if (phone?.isNotEmpty == true)
                    InfoRow(
                      icon: Icons.phone_outlined,
                      text: phone!,
                      color: TechColors.primary,
                      onTap: () => _callPhone(phone),
                    ),
                  if (schedule != null) ...[
                    const SizedBox(height: 4),
                    // Chip jadwal + estimasi dalam satu baris
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3DE),
                        border: Border.all(
                          color: const Color(0xFF97C459),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: TechColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formatDate(
                              schedule['scheduledDate'] as String?,
                              includeDay: true,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: TechColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (schedule['estimatedDuration'] != null) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 11,
                                color: TechColors.primary,
                              ),
                            ),
                            Text(
                              '${schedule['estimatedDuration']} mnt',
                              style: const TextStyle(
                                fontSize: 11,
                                color: TechColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if ((schedule['note'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      InfoRow(
                        icon: Icons.notes_outlined,
                        text: schedule['note'] as String,
                      ),
                    ],
                  ],
                  if (adminNote != null && adminNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              adminNote,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[900],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Tombol Acc / Reject ──
            if (showAccReject)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Terima Tugas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TechColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
