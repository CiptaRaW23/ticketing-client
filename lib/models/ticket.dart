// models/ticket.dart
// FIXED:
// - Null safety pada semua field fromJson
// - Tambah field priority (ada di server tapi tidak di model)
// - Tambah field address, mapsLink, updatedAt
// - Helper getter: statusLabel, statusColor, priorityColor
// - Tambah toJson() untuk keperluan debugging

class Ticket {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? address;
  final String? mapsLink;
  final String createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? user;
  final List<dynamic> messages;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.address,
    this.mapsLink,
    required this.createdAt,
    this.updatedAt,
    this.user,
    List<dynamic>? messages,
  }) : messages = messages ?? [];

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Tanpa Judul',
      description: json['description'] as String? ?? '',
      // PENTING: server kirim "in-progress" (dash), bukan "in_progress"
      status: json['status'] as String? ?? 'open',
      priority: json['priority'] as String? ?? 'low',
      address: json['address'] as String?,
      mapsLink: json['mapsLink'] as String?,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      messages: json['messages'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'address': address,
      'mapsLink': mapsLink,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'user': user,
      'messages': messages,
    };
  }

  // ── Helper getters ──

  /// Label status dalam Bahasa Indonesia
  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in-progress':
        return 'Diproses';
      case 'closed':
        return 'Selesai';
      default:
        return status;
    }
  }

  /// Apakah ticket masih aktif (belum closed)
  bool get isActive => status != 'closed';

  /// Label prioritas
  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      default:
        return priority;
    }
  }

  /// Tanggal dibuat yang sudah diformat (aman, tidak crash)
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    }
  }

  /// copyWith untuk immutable update
  Ticket copyWith({String? status, String? priority, List<dynamic>? messages}) {
    return Ticket(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      address: address,
      mapsLink: mapsLink,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
      messages: messages ?? this.messages,
    );
  }
}
