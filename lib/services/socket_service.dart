import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _initialized = false;

  // [FIX 3] Daftar callback disconnect/reconnect agar bisa dipantau dari luar
  final List<Function()> _disconnectCallbacks = [];
  final List<Function()> _reconnectCallbacks = [];

  // ── Init & Connect ──

  void init() {
    if (_initialized && (_socket?.connected ?? false)) {
      print('[Socket] ✅ Sudah terhubung, skip init');
      return;
    }

    _socket?.dispose();
    _initialized = false;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
    });

    _socket!.onConnect((_) {
      _initialized = true;
      print('[Socket] ✅ Connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _initialized = false;
      print('[Socket] ❌ Disconnected');
      // [FIX 3] Beritahu semua listener disconnect
      for (final cb in _disconnectCallbacks) {
        cb();
      }
    });

    _socket!.onReconnect((_) {
      print('[Socket] 🔄 Reconnected');
      // [FIX 3] Beritahu semua listener reconnect
      for (final cb in _reconnectCallbacks) {
        cb();
      }
    });

    _socket!.onConnectError((err) => print('[Socket] ❌ Connect error: $err'));
    _socket!.onError((err) => print('[Socket] ❌ Error: $err'));
  }

  bool get isConnected => _socket?.connected ?? false;

  // ── [FIX 3] Registrasi callback status koneksi ──

  /// Dipanggil saat socket terputus dari server
  void onDisconnect(Function() callback) {
    _disconnectCallbacks.add(callback);
  }

  /// Dipanggil saat socket berhasil terhubung kembali
  void onReconnect(Function() callback) {
    _reconnectCallbacks.add(callback);
  }

  // ── Rooms ──

  void joinRoom(int ticketId, {int retryCount = 0}) {
    if (_socket?.connected ?? false) {
      _socket!.emit('joinTicketRoom', ticketId);
      print('[Socket] 📨 Joined room: ticket-$ticketId');
    } else {
      if (retryCount >= 10) {
        print('[Socket] ⚠️ Gagal join room setelah 10x retry');
        return;
      }
      Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)), () {
        joinRoom(ticketId, retryCount: retryCount + 1);
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
    _socket?.off('newMessage');
    _socket?.on('newMessage', (data) {
      print('[Socket] 📩 newMessage');
      callback(data);
    });
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

    // [FIX 3] Bersihkan juga callback status koneksi
    _disconnectCallbacks.clear();
    _reconnectCallbacks.clear();

    print('[Socket] 🧹 Listeners removed');
  }

  void removeListenersByEvent(List<String> events) {
    for (final e in events) {
      _socket?.off(e);
    }
  }

  // ── Disconnect / Dispose ──

  void disconnect() {
    _socket?.disconnect();
    _initialized = false;
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
