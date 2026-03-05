import 'package:flutter/material.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: ID + Status badge ──
              Row(
                children: [
                  Text(
                    '#${ticket.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(ticket.status, ticket.statusLabel),
                  const SizedBox(width: 6),
                  _buildPriorityBadge(ticket.priority),
                ],
              ),
              const SizedBox(height: 8),

              // ── Judul ──
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ── Deskripsi singkat ──
              Text(
                ticket.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ── Baris bawah: tanggal + icon chat ──
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    ticket.formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  // Jumlah pesan
                  if (ticket.messages.isNotEmpty) ...[
                    Icon(Icons.chat_bubble, size: 13, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.messages.length} pesan',
                      style: TextStyle(fontSize: 12, color: Colors.blue[400]),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color bg;
    Color fg;
    switch (status) {
      case 'open':
        bg = Colors.orange[100]!;
        fg = Colors.orange[800]!;
        break;
      case 'in-progress':
        bg = Colors.blue[100]!;
        fg = Colors.blue[800]!;
        break;
      case 'closed':
        bg = Colors.green[100]!;
        fg = Colors.green[800]!;
        break;
      default:
        bg = Colors.grey[200]!;
        fg = Colors.grey[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color fg;
    IconData icon;
    switch (priority) {
      case 'high':
        bg = Colors.red[100]!;
        fg = Colors.red[700]!;
        icon = Icons.keyboard_double_arrow_up;
        break;
      case 'medium':
        bg = Colors.amber[100]!;
        fg = Colors.amber[800]!;
        icon = Icons.remove;
        break;
      default: // low
        bg = Colors.grey[100]!;
        fg = Colors.grey[600]!;
        icon = Icons.keyboard_double_arrow_down;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 2),
          Text(
            ticket.priorityLabel,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
