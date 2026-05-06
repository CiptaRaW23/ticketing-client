// lib/technician/screens/technician_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../screens/login_screen.dart';
import '../widgets/technician_widgets.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final _api = ApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _user;
  int _totalDone = 0;
  int _totalActive = 0;
  int _totalAssigned = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get('/user/profile'),
        _api.get('/tickets'),
      ]);

      final tickets =
          (results[1] is Map ? (results[1]['tickets'] ?? []) : results[1])
              as List;

      if (mounted) {
        setState(() {
          _user = (results[0] as Map)['user'] as Map<String, dynamic>?;
          _totalDone = tickets.where((t) => t['status'] == 'closed').length;
          _totalActive = tickets
              .where((t) => t['status'] == 'in-progress')
              .length;
          _totalAssigned = tickets
              .where((t) => t['status'] == 'assigned')
              .length;
        });
      }
    } catch (_) {
      await _loadFromPrefs();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _user = {
          'name': prefs.getString('userName') ?? '—',
          'username': '—',
          'phone': null,
          'email': null,
          'address': null,
        },
      );
    }
  }

  Future<void> _logout() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      content: 'Kamu perlu login kembali untuk mengakses aplikasi.',
      confirmLabel: 'Logout',
      confirmColor: Colors.red[600]!,
      headerIcon: Icons.logout_rounded,
      headerIconBg: Colors.red[50],
      headerIconColor: Colors.red[600],
    );
    if (!ok || !mounted) return;

    SocketService().disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  bool _isEmpty(String key) {
    final v = _user?[key] as String?;
    return v == null || v.isEmpty;
  }

  String _field(String key) {
    final v = _user?[key] as String?;
    return (v?.isNotEmpty == true) ? v! : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bg,
      body: _isLoading
          ? const TechLoader()
          : RefreshIndicator(
              color: TechColors.primary,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ──
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: TechColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: GradientAppBarBackground(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            TechAvatar(
                              name: _user?['name'] ?? 'T',
                              size: 76,
                              fontSize: 30,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _user?['name'] ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '🔧  Teknisi Lapangan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
                          // ── Highlight: tugas pending ──
                          if (_totalAssigned > 0) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$_totalAssigned',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tugas menunggu konfirmasi',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Segera respon assignment baru',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.orange[400],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── Stats 2-col ──
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  value: _totalActive.toString(),
                                  label: 'Aktif sekarang',
                                  icon: Icons.construction_outlined,
                                  color: TechColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  value: _totalDone.toString(),
                                  label: 'Total selesai',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.blue[700]!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Info Akun ──
                          InfoCard(
                            title: 'Informasi Akun',
                            children: [
                              InfoTile(
                                icon: Icons.person_outline,
                                label: 'Username',
                                value: _user?['username'] ?? '—',
                                isEmpty:
                                    (_user?['username'] as String?)?.isEmpty !=
                                    false,
                              ),
                              InfoTile(
                                icon: Icons.phone_outlined,
                                label: 'No. HP',
                                value: _field('phone'),
                                isEmpty: _isEmpty('phone'),
                              ),
                              InfoTile(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _field('email'),
                                isEmpty: _isEmpty('email'),
                              ),
                              InfoTile(
                                icon: Icons.location_on_outlined,
                                label: 'Alamat',
                                value: _field('address'),
                                isEmpty: _isEmpty('address'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Logout ──
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Keluar dari Akun',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
