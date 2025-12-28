import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket _socket;

  void init() {
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();
  }

  void joinRoom(int ticketId) => _socket.emit('joinTicketRoom', ticketId);

  void sendMessage(int ticketId, String message) {
    _socket.emit('sendMessage', {
      'ticketId': ticketId,
      'message': message,
      'sender': 'customer',
    });
  }

  void onNewMessage(Function(dynamic) callback) =>
      _socket.on('newMessage', callback);

  void onTicketUpdate(Function callback) =>
      _socket.on('ticketUpdated', (_) => callback());

  void dispose() => _socket.dispose();
}
