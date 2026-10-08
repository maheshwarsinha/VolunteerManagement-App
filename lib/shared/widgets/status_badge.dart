// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';
import 'package:volunteers_management/features/map/models/live_location_model.dart';

class StatusBadge extends StatelessWidget {
  final MarkerActivityStatus status;
  final bool showLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final label = status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: status == MarkerActivityStatus.online
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1)]
                  : null,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
