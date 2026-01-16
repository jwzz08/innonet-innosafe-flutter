import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WorkerInfoSheet extends StatelessWidget {
  final String zoneName;
  final int workerCount;

  const WorkerInfoSheet({super.key, required this.zoneName, required this.workerCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들러
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.group, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(zoneName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("$workerCount Workers", style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Divider(color: AppTheme.border),

          // 작업자 리스트
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: workerCount,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.surfaceHighlight,
                        child: Text("W${index+1}", style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Worker Name ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Text("Team A • Safety Manager", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      // 상태 표시
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("Normal", style: TextStyle(color: AppTheme.success, fontSize: 10)),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}