import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ActivityTile extends StatelessWidget {
  final String time;
  final String badgeText;
  final String desc;
  final String location;
  final bool isAlarm;

  const ActivityTile({
    super.key,
    required this.time,
    required this.badgeText,
    required this.desc,
    required this.location,
    this.isAlarm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAlarm ? AppTheme.danger.withOpacity(0.2) : AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: isAlarm ? AppTheme.danger : AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),

        Text(
            desc,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500
            )
        ),

        const SizedBox(height: 6),

        // 위치 정보
        Row(
          children: [
            Icon(isAlarm ? Icons.location_on : Icons.settings_input_antenna, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                  location,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis
              ),
            ),
          ],
        )
      ],
    );
  }
}