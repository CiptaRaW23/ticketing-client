import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/ticket.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupInterceptors();
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ── Interceptors ──

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // FIXED: inject token via interceptor, bukan manual setiap request
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) {
          // FIXED: format error yang ramah sebelum dilempar ke UI
          handler.next(_handleDioError(e));
        },
      ),
    );
  }

  DioException _handleDioError(DioException e) {
    String message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Koneksi timeout. Periksa jaringan Anda.';
        break;
      case DioExceptionType.connectionError:
        message = 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final serverMsg = e.response?.data is Map
            ? e.response?.data['error']
            : null;
        if (statusCode == 401) {
          message = serverMsg ?? 'Sesi habis, silakan login kembali';
        } else if (statusCode == 403) {
          message = serverMsg ?? 'Akses ditolak';
        } else if (statusCode == 404) {
          message = serverMsg ?? 'Data tidak ditemukan';
        } else if (statusCode != null && statusCode >= 500) {
          message = 'Terjadi kesalahan di server. Coba lagi nanti.';
        } else {
          message =
              serverMsg ?? 'Terjadi kesalahan (${statusCode ?? "unknown"})';
        }
        break;
      default:
        message = 'Terjadi kesalahan tidak diketahui';
    }
    return DioException(
      requestOptions: e.requestOptions,
      response: e.response,
      type: e.type,
      error: message, // pesan yang ramah
    );
  }

  /// Extract pesan error yang bisa langsung ditampilkan ke user
  static String errorMessage(Object e) {
    if (e is DioException) {
      return e.error?.toString() ?? 'Terjadi kesalahan';
    }
    return e.toString();
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      '/api/login',
      data: {'username': username, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ==================== TICKETS ====================

  Future<List<Ticket>> getTickets() async {
    final response = await _dio.get('/api/tickets');
    return (response.data as List)
        .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Ticket> getTicketDetail(int id) async {
    final response = await _dio.get('/api/tickets/$id');
    return Ticket.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Ticket> createTicket(
    String title,
    String description, {
    String? address,
  }) async {
    final response = await _dio.post(
      '/api/tickets',
      data: {
        'title': title,
        'description': description,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
    // FIXED: return ticket object, bukan void — bisa langsung update UI
    return Ticket.fromJson(response.data as Map<String, dynamic>);
  }

  // ==================== USER PROFILE ====================

  Future<User> getUserProfile() async {
    final response = await _dio.get('/api/user/profile');
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({String? name, String? address}) async {
    final data = <String, dynamic>{};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (address != null)
      data['address'] = address; // boleh kirim string kosong untuk clear
    final response = await _dio.patch('/api/user/profile', data: data);
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/user/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }
}
