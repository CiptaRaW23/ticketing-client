import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'Customer';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Customer';
      // Data mock, nanti bisa diganti dengan API
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Data diperbarui')));
        },
        child: CustomScrollView(
          slivers: [
            // Simple App Bar
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Halo, $userName',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.support_agent,
                            color: Colors.black87,
                            size: 30,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hubungi Customer Service'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PENGUMUMAN SECTION
                    _buildAnnouncementBanner(),

                    const SizedBox(height: 24),

                    // QUICK ACTIONS TITLE
                    const Text(
                      'Menu Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6 QUICK ACTION BUTTONS
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

  // ============================================
  // PENGUMUMAN BANNER (Static/Permanen)
  // ============================================
  Widget _buildAnnouncementBanner() {
    return _buildAnnouncementCard(
      icon: Icons.waving_hand,
      iconColor: Colors.blue,
      bgGradient: [Colors.blue[50]!, Colors.blue[100]!],
      title: 'Selamat Datang!',
      subtitle:
          'Gunakan menu cepat di bawah untuk mengakses berbagai panduan dan tips internet',
      date: 'Info',
    );
  }

  Widget _buildAnnouncementCard({
    required IconData icon,
    required Color iconColor,
    required List<Color> bgGradient,
    required String title,
    required String subtitle,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 6 QUICK ACTION BUTTONS (3x2 Grid)
  // ============================================
  Widget _buildQuickActionsGrid() {
    final actions = [
      QuickActionItem(
        icon: Icons.refresh,
        label: 'Panduan\nRestart',
        description: 'Cara restart router agar koneksi segar kembali',
        color: Colors.indigo,
        gradient: [Colors.indigo[400]!, Colors.indigo[600]!],
      ),
      QuickActionItem(
        icon: Icons.menu_book,
        label: 'Kamus\nNet',
        description: 'Penjelasan istilah internet dengan bahasa orang awam',
        color: Colors.cyan,
        gradient: [Colors.cyan[400]!, Colors.cyan[600]!],
      ),
      QuickActionItem(
        icon: Icons.wifi_password,
        label: 'Panduan\nWiFi',
        description: 'Cara ganti password & posisi router yang benar',
        color: Colors.blue,
        gradient: [Colors.blue[400]!, Colors.blue[600]!],
      ),
      QuickActionItem(
        icon: Icons.signal_wifi_4_bar,
        label: 'Tips\nSinyal',
        description: 'Edukasi agar sinyal tidak terhalang benda logam/tembok',
        color: Colors.purple,
        gradient: [Colors.purple[400]!, Colors.purple[600]!],
      ),
      QuickActionItem(
        icon: Icons.help_outline,
        label: 'Panduan\nUmum',
        description: 'Tutorial lengkap penggunaan internet untuk pemula',
        color: Colors.orange,
        gradient: [Colors.orange[400]!, Colors.orange[600]!],
      ),
      QuickActionItem(
        icon: Icons.lightbulb_outline,
        label: 'Tips\nHemat',
        description: 'Cara menghemat kuota dan mengoptimalkan koneksi',
        color: Colors.green,
        gradient: [Colors.green[400]!, Colors.green[600]!],
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
      itemBuilder: (ctx, index) {
        final action = actions[index];
        return _buildQuickActionButton(action);
      },
    );
  }

  Widget _buildQuickActionButton(QuickActionItem action) {
    return InkWell(
      onTap: () {
        // Tidak ada aksi untuk demo
      },
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
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
            child: Icon(action.icon, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final List<Color> gradient;

  QuickActionItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.gradient,
  });
}
