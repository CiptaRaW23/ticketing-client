import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket _socket;
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print('✅ Socket connected: ${_socket.id}');
      _isInitialized = true;
    });

    _socket.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    _socket.onError((error) {
      print('❌ Socket error: $error');
    });
  }

  void joinRoom(int ticketId) {
    if (!_isInitialized) {
      print('⚠️ Socket belum siap, tunggu sebentar...');
      Future.delayed(const Duration(milliseconds: 500), () {
        joinRoom(ticketId);
      });
      return;
    }
    _socket.emit('joinTicketRoom', ticketId);
    print('📨 Client join room: ticket-$ticketId');
  }

  void sendMessage(int ticketId, String message) {
    print('📤 Sending message: $message');
    _socket.emit('sendMessage', {
      'ticketId': ticketId,
      'message': message,
      'sender': 'customer',
    });
  }

  void onNewMessage(Function(dynamic) callback) {
    _socket.on('newMessage', (data) {
      print('📩 New message received: $data');
      callback(data);
    });
  }

  void onTicketUpdate(Function callback) {
    _socket.on('ticketUpdated', (_) {
      print('🔄 Ticket updated');
      callback();
    });
  }

  void dispose() {
    _socket.dispose();
    _isInitialized = false;
  }
}
