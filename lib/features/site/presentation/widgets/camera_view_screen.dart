import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class CameraViewScreen extends StatefulWidget {
  final String equipmentName;

  const CameraViewScreen({super.key, required this.equipmentName});

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    // 들어올 때 가로모드 허용 (사용자가 돌리면 돌아감)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 나갈 때 세로모드 고정
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.equipmentName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. 카메라 뷰 (InteractiveViewer로 줌 지원)
          Center(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 5.0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF121212),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text("Connecting to RTSP Stream...", style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. 오버레이 컨트롤 (줌 리셋 등)
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white24,
              child: const Icon(Icons.zoom_out_map, color: Colors.white),
              onPressed: () {
                _transformController.value = Matrix4.identity();
              },
            ),
          ),

          // 3. 라이브 표시
          Positioned(
            top: 50,
            right: 45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(4)),
              child: const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          )
        ],
      ),
    );
  }
}