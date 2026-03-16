import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'Customer';

  AnimationController? _animController;
  List<Animation<double>>? _fadeAnims;
  List<Animation<Offset>>? _slideAnims;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _loadUserData();
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'Customer';
      });
      _animController?.forward(from: 0);
    }
  }

  Animation<double> _fade(int i) =>
      _fadeAnims?[i] ?? const AlwaysStoppedAnimation(1.0);

  Animation<Offset> _slide(int i) =>
      _slideAnims?[i] ?? const AlwaysStoppedAnimation(Offset.zero);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FadeSlide(
                      fade: _fade(1),
                      slide: _slide(1),
                      child: _buildHeroCard(),
                    ),
                    const SizedBox(height: 20),
                    _FadeSlide(
                      fade: _fade(2),
                      slide: _slide(2),
                      child: const Text(
                        'Menu Cepat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF263238),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FadeSlide(
                      fade: _fade(3),
                      slide: _slide(3),
                      child: _buildQuickActionsGrid(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return _FadeSlide(
      fade: _fade(0),
      slide: _slide(0),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF66BB6A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $_userName 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Semoga harimu menyenangkan!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✨ Selamat Datang!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Panduan & Tips\nInternet Cepat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gunakan menu cepat di bawah\nuntuk panduan internet Anda',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // FIXED: tambah ikon dekoratif di sisi kanan hero card
                  const SizedBox(width: 12),
                  Opacity(
                    opacity: 0.25,
                    child: const Icon(
                      Icons.wifi_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      _QuickAction(
        icon: Icons.refresh_rounded,
        label: 'Panduan\nRestart',
        color: Colors.indigo,
        gradient: [Colors.indigo[400]!, Colors.indigo[600]!],
        content: 'Cara Restart Router',
        detail:
            '1. Matikan router dengan cabut kabel listrik\n2. Tunggu 30 detik\n3. Colokkan kembali\n4. Tunggu 1-2 menit hingga lampu menyala stabil\n5. Coba koneksi kembali\n\n💡 Restart rutin setiap minggu bisa menjaga performa internet!',
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: 'Kamus\nNet',
        color: Colors.cyan[700]!,
        gradient: [Colors.cyan[400]!, Colors.cyan[600]!],
        content: 'Istilah Internet',
        detail:
            '• Bandwidth: Kapasitas maksimal koneksi internet\n• Latency/Ping: Waktu respons jaringan (semakin kecil semakin baik)\n• Mbps: Megabit per second, satuan kecepatan internet\n• Router: Alat yang memancarkan sinyal WiFi di rumah\n• Modem: Penghubung jaringan ISP ke rumah Anda',
      ),
      _QuickAction(
        icon: Icons.wifi_password_rounded,
        label: 'Panduan\nWiFi',
        color: Colors.green[700]!,
        gradient: [Colors.green[400]!, Colors.green[700]!],
        content: 'Cara Ganti Password WiFi',
        detail:
            '1. Buka browser, ketik 192.168.1.1\n2. Login dengan admin/admin (atau lihat stiker di router)\n3. Cari menu Wireless > Security\n4. Ubah kolom Password/Key\n5. Gunakan kombinasi huruf + angka minimal 8 karakter\n6. Simpan perubahan & reconnect semua perangkat',
      ),
      _QuickAction(
        icon: Icons.signal_wifi_4_bar_rounded,
        label: 'Tips\nSinyal',
        color: Colors.purple,
        gradient: [Colors.purple[400]!, Colors.purple[600]!],
        content: 'Tips Memperkuat Sinyal',
        detail:
            '• Letakkan router di posisi tengah rumah\n• Hindari dekat microwave, TV, atau tembok tebal\n• Posisi tegak (vertikal) lebih baik\n• Jauhkan dari benda logam dan akuarium\n• Naikkan posisi router (di rak/meja tinggi lebih baik)\n• Pastikan tidak ada banyak dinding/lantai beton di antara router dan perangkat',
      ),
      _QuickAction(
        icon: Icons.help_rounded,
        label: 'Panduan\nUmum',
        color: Colors.orange[700]!,
        gradient: [Colors.orange[400]!, Colors.orange[600]!],
        content: 'Panduan Umum Internet',
        detail:
            '• Jika internet lambat: coba restart router & modem\n• Jika tidak bisa konek: periksa kabel & lampu router\n• Lampu ONT/Modem harus menyala hijau\n• Jika mati lampu tiba-tiba, router butuh restart setelah listrik nyala\n• Hapus cache browser jika website tidak bisa dibuka\n• Hubungi customer service jika masalah berlanjut >1 jam',
      ),
      _QuickAction(
        icon: Icons.lightbulb_rounded,
        label: 'Tips\nHemat',
        color: Colors.green[600]!,
        gradient: [Colors.green[300]!, Colors.green[600]!],
        content: 'Tips Hemat Kuota',
        detail:
            '• Nonaktifkan update otomatis aplikasi saat menggunakan data seluler\n• Streaming video — pilih resolusi 480p daripada 1080p\n• Gunakan WiFi untuk download file besar\n• Aktifkan Data Saver di browser dan aplikasi\n• Jadwalkan backup otomatis saat WiFi tersambung\n• Matikan sinkronisasi cloud yang tidak penting',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) => _ActionButton(
        action: actions[i],
        onTap: () => _showGuideSheet(actions[i]),
      ),
    );
  }

  void _showGuideSheet(_QuickAction action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuideSheet(action: action),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;
  const _FadeSlide({
    required this.fade,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final _QuickAction action;
  final VoidCallback onTap;
  const _ActionButton({required this.action, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.action.gradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.action.color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.action.icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF37474F),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSheet extends StatelessWidget {
  final _QuickAction action;
  const _GuideSheet({required this.action});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: action.gradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action.content,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Text(
                  action.detail,
                  style: const TextStyle(
                    height: 1.7,
                    fontSize: 13.5,
                    color: Color(0xFF455A64),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;
  final String content;
  final String detail;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.content,
    required this.detail,
  });
}
