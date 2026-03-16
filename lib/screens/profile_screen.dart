// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/user.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _api.getUserProfile();
      if (mounted)
        setState(() {
          _user = userData;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load profil: ${ApiService.errorMessage(e)}'),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SocketService().dispose();
      await _api.logout();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToEditProfile() async {
    if (_user == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
    );
    if (result == true) _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Gagal memuat profil'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profil',
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // CHANGED: biru → hijau
                  colors: [Colors.green[400]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: Text(
                      _user!.name.isNotEmpty
                          ? _user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        // CHANGED: biru → hijau
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _user!.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_user!.username}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _user!.isActive
                          ? Colors.green[400]
                          : Colors.red[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _user!.isActive ? 'Akun Aktif' : 'Akun Nonaktif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Info Akun ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Informasi Akun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.person, 'Username', _user!.username),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(Icons.badge, 'Nama Lengkap', _user!.name),
                  const Divider(height: 1, indent: 56),
                  _buildInfoTile(
                    Icons.location_on,
                    'Alamat',
                    _user!.address?.isNotEmpty == true
                        ? _user!.address!
                        : 'Belum diatur',
                    valueColor: _user!.address == null ? Colors.grey : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Logout ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return ListTile(
      // CHANGED: biru → hijau
      leading: Icon(icon, color: Colors.green),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          color: valueColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================
// EDIT PROFILE SCREEN
// ============================================

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final oldPass = _oldPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    bool changePassword = oldPass.isNotEmpty || newPass.isNotEmpty;

    if (changePassword) {
      if (oldPass.isEmpty || newPass.isEmpty) {
        _showSnackBar('Password lama dan baru harus diisi', isError: true);
        return;
      }
      if (newPass != confirm) {
        _showSnackBar('Password baru tidak cocok', isError: true);
        return;
      }
      if (newPass.length < 6) {
        _showSnackBar('Password minimal 6 karakter', isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _api.updateProfile(
        name: name,
        address: address.isEmpty ? null : address,
      );

      if (changePassword) {
        await _api.changePassword(oldPassword: oldPass, newPassword: newPass);
      }

      if (!mounted) return;
      _showSnackBar(
        changePassword
            ? 'Profil dan password berhasil diupdate'
            : 'Profil berhasil diupdate',
        isError: false,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'Gagal update: ${ApiService.errorMessage(e)}',
        isError: true,
      );
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info Pribadi ──
            const Text(
              'Informasi Pribadi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama tidak boleh kosong'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
                hintText: 'Masukkan alamat lengkap',
              ),
            ),

            const SizedBox(height: 32),
            const Divider(thickness: 1.5),
            const SizedBox(height: 16),

            // ── Ganti Password ──
            const Text(
              'Ganti Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kosongkan jika tidak ingin ganti password',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            _buildPassField(
              _oldPassCtrl,
              'Password Lama',
              _obscureOld,
              () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 16),
            _buildPassField(
              _newPassCtrl,
              'Password Baru',
              _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),
            _buildPassField(
              _confirmPassCtrl,
              'Konfirmasi Password Baru',
              _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),

            const SizedBox(height: 32),

            // ── Tombol Simpan ──
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                // CHANGED: biru → hijau
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPassField(
    TextEditingController ctrl,
    String label,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleObscure,
        ),
      ),
    );
  }
}
