// lib/technician/screens/technician_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../widgets/technician_widgets.dart';

class TechnicianDetailScreen extends StatefulWidget {
  final int ticketId;
  const TechnicianDetailScreen({super.key, required this.ticketId});

  @override
  State<TechnicianDetailScreen> createState() => _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState extends State<TechnicianDetailScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isUpdating = false;
  int _uploadProgress = 0;
  String? _uploadFileName;

  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get('/tickets/${widget.ticketId}'),
        _api.get('/tickets/${widget.ticketId}/photos'),
      ]);
      if (mounted) {
        setState(() {
          final raw = results[0];
          _ticket =
              (raw is Map && raw.containsKey('ticket') ? raw['ticket'] : raw)
                  as Map<String, dynamic>;
          _photos = ((results[1]['photos'] ?? []) as List)
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal memuat data',
        subtitle: ApiService.errorMessage(e),
        type: SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Update Status (hanya untuk mulai pengerjaan) ───────
  Future<void> _updateStatus(String newStatus) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Mulai pengerjaan?',
      content:
          'Status ticket akan berubah ke In Progress dan kamu mulai mengerjakan.',
      confirmLabel: 'Ya, Mulai',
      confirmColor: TechColors.primary,
      headerIcon: Icons.play_circle_outline_rounded,
      headerIconBg: const Color(0xFFE8F5E9),
      headerIconColor: TechColors.primary,
    );
    if (!ok || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await _api.patch('/tickets/${widget.ticketId}', {'status': newStatus});
      showSemanticSnack(
        context,
        'Status diperbarui ke In Progress',
        subtitle: 'Silakan mulai kerjakan dan kirim foto bukti',
        type: SnackType.success,
      );
      await _load();
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal mengubah status',
        subtitle: ApiService.errorMessage(e),
        type: SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Mark Done — kirim ke /done, tunggu konfirmasi admin ──
  Future<void> _markDone() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Tandai pekerjaan selesai?',
      content:
          'Admin akan memverifikasi foto bukti dan mengkonfirmasi ke pelanggan. '
          'Ticket baru ditutup setelah admin approve.',
      confirmLabel: 'Ya, Tandai Selesai',
      confirmColor: Colors.green[700]!,
      headerIcon: Icons.check_circle_outline_rounded,
      headerIconBg: const Color(0xFFEAF3DE),
      headerIconColor: Colors.green[700],
    );
    if (!ok || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await _api.post('/tickets/${widget.ticketId}/done', {});
      showSemanticSnack(
        context,
        'Berhasil ditandai selesai',
        subtitle: 'Menunggu verifikasi dan konfirmasi dari admin',
        type: SnackType.success,
      );
      await _load();
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal menandai selesai',
        subtitle: ApiService.errorMessage(e),
        type: SnackType.error,
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Upload Foto ────────────────────────────────────────
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kirim Foto Bukti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Maks. 5 foto · JPG, PNG',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: IconBox(
                icon: Icons.camera_alt_rounded,
                color: TechColors.primary,
                bgColor: const Color(0xFFEAF3DE),
              ),
              title: const Text(
                'Ambil Foto',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'Kamera langsung',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: IconBox(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFF185FA5),
                bgColor: const Color(0xFFE6F1FB),
              ),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(
                'Pilih beberapa sekaligus',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (file == null || !mounted) return;

      // Dialog keterangan foto
      String caption = '';
      final ctrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keterangan Foto',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Contoh: Kondisi kabel setelah diperbaiki (opsional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Lewati'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TechColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                caption = ctrl.text.trim();
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      ctrl.dispose();

      if (!mounted) return;
      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
        _uploadFileName = file.path.split('/').last;
      });
      await _uploadPhoto(File(file.path), caption);
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal memilih foto',
        subtitle: e.toString(),
        type: SnackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadFileName = null;
        });
      }
    }
  }

  Future<void> _uploadPhoto(File file, String caption) async {
    // Validasi file masih ada
    if (!await file.exists()) {
      showSemanticSnack(
        context,
        'File tidak ditemukan',
        subtitle: 'Coba pilih foto lagi',
        type: SnackType.error,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final formData = FormData.fromMap({
        'photos': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        if (caption.isNotEmpty) 'captions': caption,
      });

      await _api.dio.post(
        '$serverUrl/api/tickets/${widget.ticketId}/photos',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: (sent, total) {
          if (total <= 0 || !mounted) return;
          setState(() => _uploadProgress = (sent / total * 100).round());
        },
      );

      showSemanticSnack(
        context,
        'Foto berhasil dikirim',
        subtitle: 'Tersimpan di galeri foto ticket',
        type: SnackType.success,
      );
      await _load();
    } catch (e) {
      showSemanticSnack(
        context,
        'Gagal upload foto',
        subtitle: ApiService.errorMessage(e),
        type: SnackType.error,
      );
    }
  }

  void _openPhoto(String url, int index) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _PhotoViewer(
        url: '$serverUrl$url',
        current: index + 1,
        total: _photos.length,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: TechColors.bg, body: TechLoader());
    }
    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: EmptyState(
          icon: Icons.search_off_rounded,
          message: 'Ticket tidak ditemukan',
          subtitle: 'Mungkin sudah dihapus atau tidak ada aksesnya',
          onRefresh: _load,
        ),
      );
    }

    final t = _ticket!;
    final status = t['status'] as String? ?? 'assigned';

    // ── Perubahan B: tambah technicianDone & state baru ──
    final technicianDone = t['technicianDone'] as bool? ?? false;
    final canStart = status == 'assigned';
    final canClose = status == 'in-progress' && !technicianDone;
    final isWaiting = status == 'in-progress' && technicianDone;
    final isClosed = status == 'closed';

    final schedule = t['visitSchedule'] as Map<String, dynamic>?;
    final assignments = t['assignments'] as List?;
    final adminNote = assignments?.isNotEmpty == true
        ? (assignments!.first as Map<String, dynamic>)['adminNote'] as String?
        : null;

    return Scaffold(
      backgroundColor: TechColors.bg,
      appBar: AppBar(
        backgroundColor: TechColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket #${t['id']}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              'Detail tugas',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBanner(status: isWaiting ? 'in-progress-done' : status),
            const SizedBox(height: 16),

            // ── Info Ticket ──
            SectionCard(
              title: 'Informasi Ticket',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  DetailRow(
                    label: 'Judul',
                    value: t['title'] ?? '—',
                    bold: true,
                  ),
                  DetailRow(label: 'Deskripsi', value: t['description'] ?? '—'),
                  DetailRow(
                    label: 'Customer',
                    value: t['user']?['name'] ?? '—',
                  ),
                  if ((t['user']?['phone'] as String?)?.isNotEmpty == true)
                    DetailRow(label: 'No. HP', value: t['user']['phone']),
                  if ((t['address'] as String?)?.isNotEmpty == true)
                    DetailRow(label: 'Alamat', value: t['address']),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Jadwal Kunjungan ──
            if (schedule != null) ...[
              SectionCard(
                title: 'Jadwal Kunjungan',
                icon: Icons.calendar_month_rounded,
                iconColor: TechColors.primary,
                child: Column(
                  children: [
                    DetailRow(
                      label: 'Tanggal',
                      value: formatDate(schedule['scheduledDate'] as String?),
                      valueColor: TechColors.primary,
                    ),
                    if (schedule['estimatedDuration'] != null)
                      DetailRow(
                        label: 'Estimasi',
                        value: '${schedule['estimatedDuration']} menit',
                      ),
                    if ((schedule['note'] as String?)?.isNotEmpty == true)
                      DetailRow(label: 'Catatan', value: schedule['note']),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Catatan Admin ──
            if (adminNote != null && adminNote.isNotEmpty) ...[
              AdminNoteBanner(note: adminNote),
              const SizedBox(height: 12),
            ],

            // ── Foto Bukti ──
            SectionCard(
              title: 'Foto Bukti (${_photos.length})',
              icon: Icons.photo_library_outlined,
              trailing: !isClosed
                  ? GestureDetector(
                      onTap: _isUploading ? null : _showPhotoOptions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isUploading
                              ? Colors.grey
                              : TechColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Kirim Foto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  // Hint upload
                  if (!isClosed && _photos.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF85B7EB),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFF185FA5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Foto harus jelas dan menunjukkan area yang diperbaiki',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Progress bar saat upload
                  if (_isUploading)
                    UploadProgressBar(
                      progress: _uploadProgress,
                      fileName: _uploadFileName,
                    ),

                  // Grid foto
                  if (_photos.isEmpty && !_isUploading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada foto bukti',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_photos.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _photos.length,
                      itemBuilder: (ctx, i) {
                        final p = _photos[i];
                        return GestureDetector(
                          onTap: () => _openPhoto(p['url'] as String, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: '$serverUrl${p['url']}',
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: TechColors.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey[100],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: Colors.grey[400],
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Gagal load',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if ((p['caption'] as String?)?.isNotEmpty ==
                                    true)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      color: Colors.black54,
                                      child: Text(
                                        p['caption'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ──
            if (canStart)
              ActionButton(
                label: 'Mulai Pengerjaan',
                icon: Icons.play_circle_outline_rounded,
                color: TechColors.primary,
                isLoading: _isUpdating,
                onPressed: () => _updateStatus('in-progress'),
              ),

            // ── Perubahan C: onPressed pakai _markDone ──
            if (canClose) ...[
              if (_photos.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kirim minimal 1 foto bukti sebelum menyelesaikan ticket',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ActionButton(
                label: 'Tandai Selesai',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green[700]!,
                isLoading: _isUpdating,
                disabled: _photos.isEmpty,
                onPressed: _markDone, // ← perubahan C
              ),
            ],

            // ── Perubahan D: banner menunggu konfirmasi admin ──
            if (isWaiting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.purple[700],
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menunggu konfirmasi admin',
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Admin sedang memverifikasi foto bukti dan '
                            'mengkonfirmasi ke pelanggan. '
                            'Ticket akan ditutup setelah admin approve.',
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (isClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green[700],
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ticket telah selesai dikerjakan',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Full Screen Photo Viewer ──────────────────────────────
class _PhotoViewer extends StatefulWidget {
  final String url;
  final int current;
  final int total;
  const _PhotoViewer({required this.url, this.current = 1, this.total = 1});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  bool _hintVisible = true;

  @override
  void initState() {
    super.initState();
    // Hint zoom otomatis hilang setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text('Foto ${widget.current} dari ${widget.total}'),
    ),
    body: Stack(
      children: [
        Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: widget.url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
              errorWidget: (_, __, ___) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat foto',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Hint zoom — fade out otomatis
        AnimatedOpacity(
          opacity: _hintVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Cubit untuk zoom',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
