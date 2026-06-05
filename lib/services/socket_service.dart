import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _initialized = false;

  int? _activeTicketRoom;
  Function(dynamic)? _newMessageCallback;

  final List<Function()> _disconnectCallbacks = [];
  final List<Function()> _reconnectCallbacks = [];

  // ── Init & Connect ──

  void init() {
    print('[Socket] INIT DIPANGGIL');

    if (_initialized && (_socket?.connected ?? false)) {
      print('[Socket] ✅ Sudah terhubung, skip init');
      return;
    }

    _socket?.dispose();
    _initialized = false;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
    });

    print('[Socket] SOCKET CREATED');

    _socket!.connect();

    print('[Socket] CONNECT DIPANGGIL');

    _socket!.onConnect((_) {
      _initialized = true;
      print('[Socket] ✅ Connected: ${_socket!.id}');
    });

    _socket!.onConnectError((err) {
      print('[Socket] ❌ Connect error: $err');
    });

    _socket!.onError((err) {
      print('[Socket] ❌ Error: $err');
    });

    _socket!.onDisconnect((_) {
      _initialized = false;
      print('[Socket] ❌ Disconnected');
    });
  }

  bool get isConnected => _socket?.connected ?? false;

  /// Dipanggil saat socket terputus dari server
  void onDisconnect(Function() callback) {
    _disconnectCallbacks.add(callback);
  }

  void onReconnect(Function() callback) {
    _reconnectCallbacks.add(callback);
  }

  // ── Rooms ──

  void joinRoom(int ticketId, {int retryCount = 0}) {
    _activeTicketRoom = ticketId;

    if (_socket?.connected ?? false) {
      _socket!.emit('joinTicketRoom', ticketId);
      print('[Socket] 📨 Joined room: ticket-$ticketId');
    } else {
      print('[Socket] ⏳ Tunggu connect lalu join room: $ticketId');
      _socket?.once('connect', (_) {
        _socket!.emit('joinTicketRoom', ticketId);
        print('[Socket] 📨 Joined room (setelah connect): ticket-$ticketId');
      });
    }
  }

  void joinTechnicianRoom(int technicianId, {int retryCount = 0}) {
    if (_socket?.connected ?? false) {
      _socket!.emit('joinTechnicianRoom', technicianId);
      print('[Socket] 🔧 Joined technician room: $technicianId');
    } else {
      if (retryCount >= 10) return;
      Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)), () {
        joinTechnicianRoom(technicianId, retryCount: retryCount + 1);
      });
    }
  }

  void leaveRoom(int ticketId) {
    _socket?.emit('leaveTicketRoom', ticketId);
    _activeTicketRoom = null;
    _newMessageCallback = null;
    print('[Socket] 🚪 Left room: ticket-$ticketId');
  }

  // ── Send ──

  void sendMessage(int ticketId, String message) {
    if (!isConnected) {
      print('[Socket] ⚠️ Tidak bisa kirim, socket tidak terhubung');
      return;
    }
    _socket!.emit('sendMessage', {
      'ticketId': ticketId,
      'message': message,
      'sender': 'customer',
    });
  }

  // ── Listeners Customer ──

  void onNewMessage(Function(dynamic) callback) {
    _newMessageCallback = callback;

    _socket?.off('newMessage');

    if (_socket?.connected ?? false) {
      _socket?.on('newMessage', (data) {
        print('[Socket] 📩 newMessage');
        callback(data);
      });
    } else {
      print('[Socket] ⏳ newMessage listener akan didaftarkan setelah connect');
    }
  }

  void onTicketUpdated(Function(dynamic) callback) {
    _socket?.off('ticketUpdated');
    _socket?.on('ticketUpdated', (data) {
      print('[Socket] 🔄 ticketUpdated');
      callback(data);
    });
  }

  void onNewTicket(Function(dynamic) callback) {
    _socket?.off('newTicket');
    _socket?.on('newTicket', (data) {
      print('[Socket] 🎫 newTicket');
      callback(data);
    });
  }

  // ── Listeners Teknisi ──

  void onNewAssignment(Function(dynamic) callback) {
    _socket?.off('newAssignment');
    _socket?.on('newAssignment', (data) {
      print('[Socket] 📋 newAssignment');
      callback(data);
    });
  }

  void onTicketUpdatedTechnician(Function(dynamic) callback) {
    _socket?.off('ticketUpdated');
    _socket?.on('ticketUpdated', (data) {
      print('[Socket] 🔄 ticketUpdated (teknisi)');
      callback(data);
    });
  }

  void onTicketClosed(Function(dynamic) callback) {
    _socket?.off('ticketClosed');
    _socket?.on('ticketClosed', (data) {
      print('[Socket] ✅ ticketClosed');
      callback(data);
    });
  }

  void onConfirmationRejected(Function(dynamic) callback) {
    _socket?.off('confirmationRejected');
    _socket?.on('confirmationRejected', (data) {
      print('[Socket] ↩️ confirmationRejected');
      callback(data);
    });
  }

  // ── Remove Listeners ──

  void removeListeners() {
    _socket?.off('newMessage');
    _socket?.off('ticketUpdated');
    _socket?.off('newTicket');
    _socket?.off('newAssignment');
    _socket?.off('ticketClosed');
    _socket?.off('confirmationRejected');

    _disconnectCallbacks.clear();
    _reconnectCallbacks.clear();

    print('[Socket] 🧹 Listeners removed');
  }

  void removeChatListeners() {
    _socket?.off('newMessage');
    _disconnectCallbacks.clear();
    _reconnectCallbacks.clear();
    print('[Socket] 🧹 Chat listeners removed');
  }

  void removeListenersByEvent(List<String> events) {
    for (final e in events) {
      _socket?.off(e);
    }
  }

  // ── Disconnect / Dispose ──

  void disconnect() {
    _socket?.off('newMessage');
    _socket?.off('ticketUpdated');
    _socket?.off('newTicket');
    _socket?.off('newAssignment');
    _socket?.off('ticketClosed');
    _socket?.off('confirmationRejected');
    _disconnectCallbacks.clear();
    _reconnectCallbacks.clear();

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
    _activeTicketRoom = null;
    _newMessageCallback = null;
    print('[Socket] 🔌 Disconnected (manual)');
  }

  void dispose() {
    removeListeners();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
    print('[Socket] 🗑️ Disposed');
  }
}
