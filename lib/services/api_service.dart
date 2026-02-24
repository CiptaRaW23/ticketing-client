import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/ticket.dart';
import '../models/user.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: serverUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _setAuthHeader() async {
    final token = await _getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ==================== TICKETS ====================

  Future<List<Ticket>> getTickets() async {
    await _setAuthHeader();
    final response = await _dio.get('/api/tickets');
    return (response.data as List)
        .map((json) => Ticket.fromJson(json))
        .toList();
  }

  Future<void> createTicket(
    String title,
    String description, {
    String? address,
  }) async {
    await _setAuthHeader();
    await _dio.post(
      '/api/tickets',
      data: {
        'title': title,
        'description': description,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
  }

  Future<Ticket> getTicketDetail(int id) async {
    await _setAuthHeader();
    final response = await _dio.get('/api/tickets/$id');
    return Ticket.fromJson(response.data);
  }

  // ==================== USER PROFILE ====================

  Future<User> getUserProfile() async {
    await _setAuthHeader();
    final response = await _dio.get('/api/user/profile');
    return User.fromJson(response.data['user']);
  }

  Future<User> updateProfile({String? name, String? address}) async {
    await _setAuthHeader();
    final response = await _dio.patch(
      '/api/user/profile',
      data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
      },
    );
    return User.fromJson(response.data['user']);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _setAuthHeader();
    await _dio.post(
      '/api/user/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }
}
