// lib/technician/screens/technician_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      showSnack(context, ApiService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Update Status ──────────────────────────────────────
  Future<void> _updateStatus(String newStatus) async {
    final label = newStatus == 'in-progress' ? 'In Progress' : 'Selesai';
    final warningMsg = newStatus == 'closed'
        ? 'Pastikan pekerjaan sudah selesai dan minimal 1 foto bukti sudah dikirim.'
        : 'Status ticket akan berubah menjadi In Progress dan kamu mulai mengerjakan.';

    final ok = await showConfirmDialog(
      context,
      title: 'Ubah Status → $label?',
      content: warningMsg,
      confirmLabel: 'Ya, $label',
    );
    if (!ok || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await _api.patch('/tickets/${widget.ticketId}', {'status': newStatus});
      showSnack(
        context,
        newStatus == 'closed'
            ? '✅ Ticket berhasil diselesaikan!'
            : '✅ Status diperbarui ke In Progress',
      );
      await _load();
    } catch (e) {
      showSnack(context, ApiService.errorMessage(e));
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
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kirim Foto Bukti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: IconBox(
                icon: Icons.camera_alt,
                color: TechColors.primary,
              ),
              title: const Text(
                'Ambil Foto',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Gunakan kamera HP'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: IconBox(icon: Icons.photo_library, color: Colors.blue),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Pilih foto yang sudah ada'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
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

      String caption = '';
      final ctrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Keterangan Foto', style: TextStyle(fontSize: 16)),
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
      setState(() => _isUploading = true);
      await _uploadPhoto(File(file.path), caption);
    } catch (e) {
      showSnack(context, 'Gagal memilih foto: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadPhoto(File file, String caption) async {
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
      );
      showSnack(context, '✅ Foto berhasil dikirim!');
      await _load();
    } catch (e) {
      showSnack(context, 'Gagal upload foto: ${ApiService.errorMessage(e)}');
    }
  }

  void _openPhoto(String url) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _PhotoViewer(url: '$serverUrl$url')),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: TechColors.bg, body: TechLoader());
    }
    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: const Center(child: Text('Ticket tidak ditemukan')),
      );
    }

    final t = _ticket!;
    final status = t['status'] as String? ?? 'assigned';
    final schedule = t['visitSchedule'] as Map<String, dynamic>?;
    final assignments = t['assignments'] as List?;
    final adminNote = assignments?.isNotEmpty == true
        ? (assignments!.first as Map<String, dynamic>)['adminNote'] as String?
        : null;

    final canStart = status == 'assigned';
    final canClose = status == 'in-progress';
    final isClosed = status == 'closed';

    return Scaffold(
      backgroundColor: TechColors.bg,
      appBar: AppBar(
        backgroundColor: TechColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Ticket #${t['id']}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBanner(status: status),
            const SizedBox(height: 16),

            // Info Ticket
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

            // Jadwal Kunjungan
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

            // Catatan Admin
            if (adminNote != null && adminNote.isNotEmpty) ...[
              AdminNoteBanner(note: adminNote),
              const SizedBox(height: 12),
            ],

            // Foto Bukti
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
              child: _photos.isEmpty
                  ? Center(
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
                  : GridView.builder(
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
                          onTap: () => _openPhoto(p['url'] as String),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  '$serverUrl${p['url']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey[400],
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
            ),
            const SizedBox(height: 24),

            if (canStart)
              ActionButton(
                label: 'Mulai Pengerjaan',
                icon: Icons.play_circle_outline_rounded,
                color: TechColors.primary,
                isLoading: _isUpdating,
                onPressed: () => _updateStatus('in-progress'),
              ),

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
                onPressed: () => _updateStatus('closed'),
              ),
            ],

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
class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Foto Bukti'),
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white70, size: 60),
        ),
      ),
    ),
  );
}
