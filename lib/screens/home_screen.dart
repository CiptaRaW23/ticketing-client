// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Customer';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'Customer';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 70,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 2,
              flexibleSpace: FlexibleSpaceBar(
                background: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          'Halo, $_userName 👋',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeBanner(),
                    const SizedBox(height: 24),
                    const Text(
                      'Menu Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.waving_hand,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gunakan menu cepat di bawah untuk panduan dan tips internet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                      height: 1.4,
                    ),
                  ),
                ],
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
        icon: Icons.refresh,
        label: 'Panduan\nRestart',
        color: Colors.indigo,
        gradient: [Colors.indigo[400]!, Colors.indigo[600]!],
        content: 'Cara Restart Router',
        detail:
            '1. Matikan router dengan cabut kabel listrik\n2. Tunggu 30 detik\n3. Colokkan kembali\n4. Tunggu 1-2 menit hingga lampu menyala stabil\n5. Coba koneksi kembali\n\n💡 Restart rutin setiap minggu bisa menjaga performa internet!',
      ),
      _QuickAction(
        icon: Icons.menu_book,
        label: 'Kamus\nNet',
        color: Colors.cyan,
        gradient: [Colors.cyan[400]!, Colors.cyan[600]!],
        content: 'Istilah Internet',
        detail:
            '• Bandwidth: Kapasitas maksimal koneksi internet\n• Latency/Ping: Waktu respons jaringan (semakin kecil semakin baik)\n• Mbps: Megabit per second, satuan kecepatan internet\n• Router: Alat yang memancarkan sinyal WiFi di rumah\n• Modem: Penghubung jaringan ISP ke rumah Anda',
      ),
      _QuickAction(
        icon: Icons.wifi_password,
        label: 'Panduan\nWiFi',
        color: Colors.blue,
        gradient: [Colors.blue[400]!, Colors.blue[600]!],
        content: 'Cara Ganti Password WiFi',
        detail:
            '1. Buka browser, ketik 192.168.1.1\n2. Login dengan admin/admin (atau lihat stiker di router)\n3. Cari menu Wireless > Security\n4. Ubah kolom Password/Key\n5. Gunakan kombinasi huruf + angka minimal 8 karakter\n6. Simpan perubahan & reconnect semua perangkat',
      ),
      _QuickAction(
        icon: Icons.signal_wifi_4_bar,
        label: 'Tips\nSinyal',
        color: Colors.purple,
        gradient: [Colors.purple[400]!, Colors.purple[600]!],
        content: 'Tips Memperkuat Sinyal',
        detail:
            '• Letakkan router di posisi tengah rumah\n• Hindari dekat microwave, TV, atau tembok tebal\n• Posisi tegak (vertikal) lebih baik\n• Jauhkan dari benda logam dan akuarium\n• Naikkan posisi router (di rak/meja tinggi lebih baik)\n• Pastikan tidak ada banyak dinding/lantai beton di antara router dan perangkat',
      ),
      _QuickAction(
        icon: Icons.help_outline,
        label: 'Panduan\nUmum',
        color: Colors.orange,
        gradient: [Colors.orange[400]!, Colors.orange[600]!],
        content: 'Panduan Umum Internet',
        detail:
            '• Jika internet lambat: coba restart router & modem\n• Jika tidak bisa konek: periksa kabel & lampu router\n• Lampu ONT/Modem harus menyala hijau\n• Jika mati lampu tiba-tiba, router butuh restart setelah listrik nyala\n• Hapus cache browser jika website tidak bisa dibuka\n• Hubungi customer service jika masalah berlanjut >1 jam',
      ),
      _QuickAction(
        icon: Icons.lightbulb_outline,
        label: 'Tips\nHemat',
        color: Colors.green,
        gradient: [Colors.green[400]!, Colors.green[600]!],
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) => _buildActionButton(actions[i]),
    );
  }

  Widget _buildActionButton(_QuickAction action) {
    return InkWell(
      onTap: () => _showGuideDialog(action),
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: action.gradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: action.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(action.icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog(_QuickAction action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: action.gradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(action.content, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            action.detail,
            style: const TextStyle(height: 1.6, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
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
