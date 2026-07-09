// screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Step 1 = validasi no. HP, Step 2 = isi data diri
  int _step = 1;

  // Controllers
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Focus nodes
  final _usernameFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isValidatingPhone = false;
  bool _isSubmitting = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _validatedPhone = '';
  String _registryName = '';
  String _registryAddress = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _usernameFocus.dispose();
    _nameFocus.dispose();
    _addressFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ─── Step 1: Validasi nomor HP ────────────────────────────
  Future<void> _validatePhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _snack('No. Handphone wajib diisi', err: true);
      return;
    }
    if (phone.length < 9) {
      _snack('Nomor tidak valid', err: true);
      return;
    }

    setState(() => _isValidatingPhone = true);
    try {
      final result = await _api.validatePhone(phone);
      _validatedPhone = phone;
      _registryName = result['name'] as String? ?? '';
      _registryAddress = result['address'] as String? ?? '';
      _nameCtrl.text = _registryName;
      _addressCtrl.text = _registryAddress;
      setState(() => _step = 2);
    } catch (e) {
      _snack(ApiService.errorMessage(e), err: true);
    } finally {
      if (mounted) setState(() => _isValidatingPhone = false);
    }
  }

  // ─── Step 2: Submit ────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _api.register(
        phone: _validatedPhone,
        username: _usernameCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      _snack(ApiService.errorMessage(e), err: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3DE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF2E7D32),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registrasi Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Akun kamu sudah aktif dan siap digunakan.\nSilakan login dengan username & password yang sudah dibuat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Akun langsung aktif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login Sekarang',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_step == 2)
                        setState(() {
                          _step = 1;
                          _validatedPhone = '';
                        });
                      else
                        Navigator.pop(context);
                    },
                    color: const Color(0xFF1A1A1A),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StepDot(
                          active: _step >= 1,
                          done: _step > 1,
                          label: '1',
                        ),
                        _StepLine(active: _step > 1),
                        _StepDot(active: _step >= 2, done: false, label: '2'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                child: _step == 1 ? _buildStep1() : _buildStep2(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 1 UI ────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Cek Nomor HP',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan nomor HP yang sudah terdaftar di sistem kami untuk melanjutkan pendaftaran.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
        ),
        const SizedBox(height: 28),

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nomor HP harus sama dengan yang terdaftar sebagai pelanggan Jagonet. '
                  'Jika belum terdaftar, hubungi admin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[900],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone field
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _validatePhone(),
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: _decor(
            'No. Handphone',
            Icons.phone_outlined,
          ).copyWith(hintText: 'Contoh: 08123456789'),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isValidatingPhone ? null : _validatePhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isValidatingPhone
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Cek Nomor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sudah punya akun?',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 2 UI ────────────────────────────────────────────
  Widget _buildStep2() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Lengkapi Data Diri',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nomor HP terverifikasi. Isi data berikut untuk membuat akun.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Badge phone verified
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. HP Terverifikasi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        _validatedPhone,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _step = 1;
                    _validatedPhone = '';
                  }),
                  child: Text(
                    'Ganti',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Username
          _label('Username'),
          TextFormField(
            controller: _usernameCtrl,
            focusNode: _usernameFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _nameFocus.requestFocus(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: _decor('Username', Icons.person_outline_rounded),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim()))
                return 'Hanya huruf, angka, underscore';
              if (v.trim().length < 4) return 'Minimal 4 karakter';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Nama Lengkap
          _label('Nama Lengkap'),
          TextFormField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (_) => _addressFocus.requestFocus(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: _decor('Nama Lengkap', Icons.badge_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 14),

          // No HP (read-only)
          _label('No. Handphone'),
          TextFormField(
            initialValue: _validatedPhone,
            readOnly: true,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            decoration: _decor('No. Handphone', Icons.phone_outlined).copyWith(
              filled: true,
              fillColor: Colors.grey[100],
              suffixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Alamat
          _label('Alamat'),
          TextFormField(
            controller: _addressCtrl,
            focusNode: _addressFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: _decor('Alamat', Icons.location_on_outlined),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
          ),
          const SizedBox(height: 14),

          // Password
          _label('Password'),
          TextFormField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            obscureText: _obscurePass,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: _decor('Password', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey[500],
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Konfirmasi Password
          _label('Konfirmasi Password'),
          TextFormField(
            controller: _confirmPassCtrl,
            focusNode: _confirmFocus,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration:
                _decor(
                  'Konfirmasi Password',
                  Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Konfirmasi password wajib diisi';
              if (v != _passwordCtrl.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Text(' *', style: TextStyle(color: Colors.red, fontSize: 13)),
      ],
    ),
  );

  InputDecoration _decor(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.green, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    errorStyle: const TextStyle(fontSize: 11, height: 1.2),
  );
}

class _StepDot extends StatelessWidget {
  final bool active, done;
  final String label;
  const _StepDot({
    required this.active,
    required this.done,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = done
        ? const Color(0xFF2E7D32)
        : active
        ? Colors.green
        : Colors.grey[300]!;
    final Widget child = done
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
        : Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 2,
    color: active ? const Color(0xFF2E7D32) : Colors.grey[300],
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}
