class Ticket {
  final int id;
  final String title;
  final String description;
  final String status;
  final String createdAt;
  final Map<String, dynamic>? user;
  final List<dynamic>? messages;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.user,
    this.messages,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      createdAt: json['createdAt'],
      user: json['user'],
      messages: json['messages'],
    );
  }
}
