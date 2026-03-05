import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _initialized = false;

  // ── Init & Connect ──

  void init() {
    if (_initialized && (_socket?.connected ?? false)) {
      print('[Socket] ✅ Sudah terhubung, skip init');
      return;
    }

    // Dispose socket lama jika ada
    _socket?.dispose();
    _initialized = false;

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'], // FIXED: polling sebagai fallback
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
    });

    _socket!.onConnectError((err) {
      print('[Socket] ❌ Connect error: $err');
    });

    _socket!.onError((err) {
      print('[Socket] ❌ Error: $err');
    });

    _socket!.onReconnect((_) {
      print('[Socket] 🔄 Reconnected');
    });
  }

  bool get isConnected => _socket?.connected ?? false;

  // ── Room ──

  /// Join room ticket. Otomatis retry jika socket belum siap.
  void joinRoom(int ticketId, {int retryCount = 0}) {
    if (_socket?.connected ?? false) {
      _socket!.emit('joinTicketRoom', ticketId);
      print('[Socket] 📨 Joined room: ticket-$ticketId');
    } else {
      if (retryCount >= 10) {
        print('[Socket] ⚠️ Gagal join room setelah 10x retry');
        return;
      }
      print('[Socket] ⏳ Belum terhubung, retry ${retryCount + 1}/10...');
      Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)), () {
        joinRoom(ticketId, retryCount: retryCount + 1);
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
    print('[Socket] 📤 Message sent to ticket-$ticketId');
  }

  // ── Listeners ──
  // FIXED: selalu off() dulu sebelum on() baru agar tidak duplikat

  void onNewMessage(Function(dynamic) callback) {
    _socket?.off('newMessage'); // hapus listener lama
    _socket?.on('newMessage', (data) {
      print('[Socket] 📩 newMessage: $data');
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

  /// Hapus semua listener (dipanggil saat screen di-dispose)
  void removeListeners() {
    _socket?.off('newMessage');
    _socket?.off('ticketUpdated');
    _socket?.off('newTicket');
    print('[Socket] 🧹 Listeners removed');
  }

  // ── Dispose ──
  // FIXED: hanya disconnect, tidak destroy singleton.
  // Panggil init() lagi jika ingin reconnect.

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
