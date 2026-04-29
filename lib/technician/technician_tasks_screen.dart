// lib/technician/screens/technician_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    SocketService().removeListenersByEvent(['newAssignment', 'ticketUpdated']);
    super.dispose();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _techName = prefs.getString('userName') ?? 'Teknisi');
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
      showSnack(context, ApiService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupSocket() {
    SocketService().onNewAssignment((_) {
      if (mounted) {
        _loadTickets();
        showSnack(context, '📋 Ada tugas baru dari admin!');
      }
    });
    SocketService().onTicketUpdatedTechnician((_) {
      if (mounted) _loadTickets();
    });
  }

  Future<void> _respond(int ticketId, String action, {String? reason}) async {
    try {
      final body = <String, dynamic>{'action': action};
      if (reason != null && reason.isNotEmpty) body['rejectReason'] = reason;
      await _api.post('/tickets/$ticketId/assignment/respond', body);
      showSnack(
        context,
        action == 'accept'
            ? '✅ Tugas diterima! Status ticket → In Progress'
            : '❌ Tugas ditolak',
      );
      _loadTickets();
    } catch (e) {
      showSnack(context, ApiService.errorMessage(e));
    }
  }

  Future<void> _showRejectDialog(int ticketId) async {
    final ctrl = TextEditingController();
    final ok = await showConfirmDialog(
      context,
      title: '',
      content: '',
      confirmLabel: 'Tolak Tugas',
      confirmColor: Colors.red,
      titleWidget: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Tolak Tugas', style: TextStyle(fontSize: 17)),
        ],
      ),
    );
    // showConfirmDialog doesn't support custom content yet — use full dialog
    ctrl.dispose();
    if (!ok || !mounted) return;
    await _respond(ticketId, 'reject', reason: ctrl.text.trim());
  }

  Future<void> _showFullRejectDialog(int ticketId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Tolak Tugas', style: TextStyle(fontSize: 17)),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak Tugas'),
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
                                'Teknisi',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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

          // ── Body (scrollable) ──
          Expanded(
            child: _isLoading
                ? const TechLoader()
                : RefreshIndicator(
                    color: TechColors.primary,
                    onRefresh: _loadTickets,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_pending, showAccReject: true),
                        _buildList(_active, showAccReject: false),
                        _buildList(_done, showAccReject: false),
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
  }) {
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        message: 'Tidak ada tugas',
        subtitle: 'Tarik ke bawah untuk refresh',
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

  @override
  Widget build(BuildContext context) {
    final schedule = ticket['visitSchedule'] as Map<String, dynamic>?;
    final assignments = ticket['assignments'] as List?;
    final adminNote = assignments?.isNotEmpty == true
        ? (assignments!.first as Map<String, dynamic>)['adminNote'] as String?
        : null;

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
            // Header
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
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),

            // Body
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
                  if ((ticket['user']?['phone'] as String?)?.isNotEmpty == true)
                    InfoRow(
                      icon: Icons.phone_outlined,
                      text: ticket['user']['phone'] as String,
                      color: TechColors.primary,
                    ),
                  if (schedule != null) ...[
                    const SizedBox(height: 2),
                    InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: formatDate(
                        schedule['scheduledDate'] as String?,
                        includeDay: true,
                      ),
                      color: TechColors.primary,
                    ),
                    if (schedule['estimatedDuration'] != null)
                      InfoRow(
                        icon: Icons.timer_outlined,
                        text: 'Estimasi ${schedule['estimatedDuration']} menit',
                        color: TechColors.primary,
                      ),
                    if ((schedule['note'] as String?)?.isNotEmpty == true)
                      InfoRow(
                        icon: Icons.notes_outlined,
                        text: schedule['note'] as String,
                      ),
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

            // Tombol Acc / Reject
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
