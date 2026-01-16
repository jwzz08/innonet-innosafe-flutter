import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// 맵 레이아웃 위젯 (애니메이션, 마커, 구조물 포함)
// ---------------------------------------------------------------------------
class SiteMapLayout extends StatefulWidget {
  final double width;
  final double height;

  const SiteMapLayout({super.key, this.width = 2000, this.height = 1000});

  @override
  State<SiteMapLayout> createState() => _SiteMapLayoutState();
}

class _SiteMapLayoutState extends State<SiteMapLayout> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final String currentSite = "월판 현장 (Tunnel)";

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF0B0D10),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          Positioned.fill(child: CustomPaint(painter: TunnelStructurePainter())),

          // 마커 예시 (Tunnel이 포함되면 굴삭기, 아니면 센서)
          if (currentSite.contains("Tunnel") || true) ...[
            _buildMapNode(200, 500, Icons.construction, AppTheme.warning, "Excavator-01", "Zone A"),
            _buildMapNode(800, 480, Icons.person, AppTheme.success, "Worker: Kim", "Zone B"),
          ] else ...[
            _buildMapNode(500, 420, Icons.sensors, AppTheme.success, "Gas Sensor-04", "Zone A"),
            _buildMapNode(1100, 550, Icons.warning, AppTheme.danger, "Vibration Alert", "Zone C"),
          ]
        ],
      ),
    );
  }

  Widget _buildMapNode(double x, double y, IconData icon, Color color, String title, String zone) {
    return Positioned(
      left: x - 20, top: y - 20,
      child: GestureDetector(
        onTap: () => _showNodeDetails(title, zone, color),
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5 * _glowController.value),
                    blurRadius: 10 + (10 * _glowController.value),
                    spreadRadius: 2 * _glowController.value,
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 20),
            );
          },
        ),
      ),
    );
  }

  void _showNodeDetails(String title, String zone, Color statusColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: statusColor),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(statusColor == AppTheme.success ? "NORMAL" : "ALERT", style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _detailRow("Site", currentSite),
              _detailRow("Location", zone),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters (터널 구조물 및 그리드 그리기)
// ---------------------------------------------------------------------------
class TunnelStructurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tunnelLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 500);
    path.cubicTo(400, 500, 400, 400, 800, 500);
    path.cubicTo(1200, 600, 1600, 400, 2000, 500);

    canvas.drawPath(path, paint..color = AppTheme.tunnelLine.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    canvas.drawPath(path, paint..color = AppTheme.tunnelLine..maskFilter = null);
    canvas.drawPath(path, Paint()..color = Colors.white10..strokeWidth = 2..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}