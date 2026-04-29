import 'package:flutter/material.dart';

// ─────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────

class TechColors {
  static const primary = Color(0xFF1B5E20);
  static const primaryMid = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF388E3C);
  static const bg = Color(0xFFF5F7FA);

  static const gradientAppBar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryMid, primaryLight],
  );
}

// ─────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────

String formatDate(String? raw, {bool includeDay = false}) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final dt = DateTime.parse(raw).toLocal();
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    if (includeDay) {
      return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}  $time';
    }
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
  } catch (_) {
    return raw;
  }
}

// ─────────────────────────────────────────
// LOADING INDICATOR
// ─────────────────────────────────────────

class TechLoader extends StatelessWidget {
  final Color color;
  const TechLoader({super.key, this.color = TechColors.primary});

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(color: color));
}

// ─────────────────────────────────────────
// GRADIENT APPBAR BACKGROUND
// ─────────────────────────────────────────

class GradientAppBarBackground extends StatelessWidget {
  final Widget child;
  const GradientAppBarBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: TechColors.gradientAppBar),
    child: SafeArea(child: child),
  );
}

// ─────────────────────────────────────────
// AVATAR CIRCLE
// ─────────────────────────────────────────

class TechAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  const TechAvatar({
    super.key,
    required this.name,
    this.size = 46,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
    ),
    child: Center(
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'T',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────
// WHITE CARD WITH SHADOW
// ─────────────────────────────────────────

class TechCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const TechCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

// ─────────────────────────────────────────
// SECTION CARD
// ─────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => TechCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
        ),
        const Divider(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: child,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// DETAIL ROW
// ─────────────────────────────────────────

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? const Color(0xFF1A1A2E),
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color ?? Colors.grey[500]),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// STATUS BANNER
// ─────────────────────────────────────────

class StatusBanner extends StatelessWidget {
  final String status;
  const StatusBanner({super.key, required this.status});

  static const _cfg = {
    'assigned': {
      'label': 'Menunggu Konfirmasi Anda',
      'icon': Icons.pending_outlined,
    },
    'in-progress': {
      'label': 'Sedang Dikerjakan',
      'icon': Icons.construction_outlined,
    },
    'closed': {
      'label': 'Ticket Selesai',
      'icon': Icons.check_circle_outline_rounded,
    },
  };

  Color get _fg => status == 'assigned'
      ? Colors.orange[700]!
      : status == 'in-progress'
      ? TechColors.primary
      : Colors.green[700]!;

  Color get _bg => status == 'assigned'
      ? Colors.orange[50]!
      : status == 'in-progress'
      ? const Color(0xFFE8F5E9)
      : Colors.green[50]!;

  Color get _border => status == 'assigned'
      ? Colors.orange[200]!
      : status == 'in-progress'
      ? const Color(0xFFA5D6A7)
      : Colors.green[200]!;

  @override
  Widget build(BuildContext context) {
    final c = _cfg[status] ?? _cfg['assigned']!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(c['icon'] as IconData, color: _fg, size: 22),
          const SizedBox(width: 10),
          Text(
            c['label'] as String,
            style: TextStyle(
              color: _fg,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: (isLoading || disabled) ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// ─────────────────────────────────────────
// ICON BOX (untuk bottom sheet)
// ─────────────────────────────────────────

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const IconBox({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color),
  );
}

// ─────────────────────────────────────────
// STAT CARD (profile)
// ─────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => TechCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// INFO CARD (profile — label + daftar tile)
// ─────────────────────────────────────────

class InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => TechCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Divider(height: 1),
        ...children,
      ],
    ),
  );
}

// ─────────────────────────────────────────
// INFO TILE (profile — icon + label + value)
// ─────────────────────────────────────────

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelLabel = 'Batal',
  String confirmLabel = 'Ya',
  Color confirmColor = TechColors.primary,
  Widget? titleWidget,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: titleWidget ?? Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

// ─────────────────────────────────────────
// SNACKBAR HELPER
// ─────────────────────────────────────────

void showSnack(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ─────────────────────────────────────────
// ADMIN NOTE BANNER
// ─────────────────────────────────────────

class AdminNoteBanner extends StatelessWidget {
  final String note;
  const AdminNoteBanner({super.key, required this.note});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.amber[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber[200]!),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sticky_note_2_rounded, color: Colors.amber[700], size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catatan dari Admin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber[900],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
