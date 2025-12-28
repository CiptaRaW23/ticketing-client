import 'package:flutter/material.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(ticket.title),
        subtitle: Text(
          'Status: ${ticket.status} • ${ticket.createdAt.substring(0, 10)}',
        ),
        trailing: const Icon(Icons.chat),
        onTap: onTap,
      ),
    );
  }
}
