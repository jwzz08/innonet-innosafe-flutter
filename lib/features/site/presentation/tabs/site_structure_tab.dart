import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/worker_info_sheet.dart';
import '../widgets/camera_view_screen.dart';
import '../../provider/site_structure_provider.dart';
import '../../data/model/site_structure_model.dart';

class SiteStructureTab extends ConsumerStatefulWidget {

  final int siteId;

  const SiteStructureTab({super.key, required this.siteId});

  @override
  ConsumerState<SiteStructureTab> createState() => _SiteStructureTabState();
}

class _SiteStructureTabState extends ConsumerState<SiteStructureTab> {
  final TransformationController _transformController = TransformationController();

  bool isAllWarningLightsOn = false;
  bool _isInitialized = false;

  // 가로 모드 사이드 패널용 데이터
  WorkerGroupModel? selectedWorkerGroup;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final structureAsyncValue = ref.watch(siteStructureProvider(widget.siteId));

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        // 세로 복귀 시 패널 닫기
        if (!isLandscape && selectedWorkerGroup != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => selectedWorkerGroup = null);
          });
        }

        return Scaffold(
          floatingActionButton: isLandscape
              ? null
              : FloatingActionButton.extended(
            heroTag: "siren_fab",
            backgroundColor: isAllWarningLightsOn ? AppTheme.danger : AppTheme.surfaceHighlight,
            icon: Icon(isAllWarningLightsOn ? Icons.alarm_on : Icons.alarm_off, color: Colors.white),
            label: Text(isAllWarningLightsOn ? "Siren ON" : "Siren OFF", style: const TextStyle(color: Colors.white)),
            onPressed: () => setState(() => isAllWarningLightsOn = !isAllWarningLightsOn),
          ),

          body: structureAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: AppTheme.danger))),
            data: (siteData) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final double fitScale = constraints.maxHeight / siteData.height;

                  if (!_isInitialized) {
                    _transformController.value = Matrix4.identity()..scale(fitScale);
                    _isInitialized = true;
                  }

                  return Stack(
                    children: [
                      // 1. 맵 뷰어
                      GestureDetector(
                        onTap: () {
                          if (isLandscape && selectedWorkerGroup != null) {
                            setState(() => selectedWorkerGroup = null);
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          constrained: false,
                          boundaryMargin: EdgeInsets.zero,
                          minScale: fitScale,
                          maxScale: 4.0,
                          child: SizedBox(
                            width: siteData.width,
                            height: siteData.height,
                            child: Stack(
                              children: [
                                // 배경 이미지
                                Positioned.fill(
                                  child: Container(
                                    color: const Color(0xFF1A1D24),
                                    child: Image.asset(
                                      siteData.mapImageUrl.isNotEmpty ? siteData.mapImageUrl : "assets/img/id-83.png",
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white24)),
                                    ),
                                  ),
                                ),

                                // 장비 아이콘
                                ...siteData.equipments.map((e) => _buildEquipmentIcon(
                                  equipment: e,
                                )),

                                // 작업자 그룹 아이콘
                                ...siteData.workerGroups.map((w) => _buildWorkerGroupIcon(
                                  group: w,
                                  isLandscape: isLandscape,
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. HUD (세로 모드)
                      if (!isLandscape)
                        Positioned(
                          top: 16, left: 16, right: 16,
                          child: SafeArea(child: _buildHud(siteData)),
                        ),

                      // 3. 줌 리셋 버튼 (세로 모드)
                      if (!isLandscape)
                        Positioned(
                          bottom: 80, right: 16,
                          child: FloatingActionButton.small(
                            heroTag: "reset_view_btn",
                            backgroundColor: AppTheme.surface.withOpacity(0.8),
                            child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                            onPressed: () {
                              final matrix = Matrix4.identity()..scale(fitScale);
                              _transformController.value = matrix;
                            },
                          ),
                        ),

                      // 4. 회전 버튼들
                      if (isLandscape)
                        Positioned(
                          top: 24, left: 24,
                          child: SafeArea(
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          bottom: 80, right: 70,
                          child: FloatingActionButton.small(
                            heroTag: "landscape_btn",
                            backgroundColor: AppTheme.surfaceHighlight.withOpacity(0.9),
                            child: const Icon(Icons.screen_rotation_rounded, color: Colors.white),
                            onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]),
                          ),
                        ),

                      // 5. 사이드 패널 (가로 모드)
                      if (isLandscape && selectedWorkerGroup != null)
                        _buildSidePanel(selectedWorkerGroup!),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildHud(SiteStructureModel data) {
    final totalWorkers = data.workerGroups.fold(0, (sum, group) => sum + group.count);
    final warningCount = data.equipments.where((e) => e.status == 'Warning').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(Icons.people, "Workers", "$totalWorkers"),
          _buildDivider(),
          _buildStatusItem(Icons.warning_amber_rounded, "Alerts", "$warningCount", color: warningCount > 0 ? AppTheme.danger : AppTheme.success),
          _buildDivider(),
          _buildStatusItem(Icons.sensors, "Sensors", "24"),
          _buildDivider(),
          _buildStatusItem(Icons.thermostat, "Temp", "24°C"),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value, {Color color = Colors.white}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 24, color: AppTheme.border);

  Widget _buildEquipmentIcon({required EquipmentModel equipment}) {
    return Positioned(
      top: equipment.y - 24, left: equipment.x - 24,
      child: GestureDetector(
        onTap: () {
          if (equipment.hasCamera) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraViewScreen(equipmentName: equipment.name)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No camera connected.")));
          }
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: equipment.status == 'Warning' ? AppTheme.danger : (equipment.hasCamera ? AppTheme.primary : AppTheme.textSecondary),
                    width: 2
                ),
                boxShadow: [
                  if (equipment.hasCamera) BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                ],
              ),
              child: Icon(Icons.construction, color: equipment.hasCamera ? Colors.white : AppTheme.textSecondary, size: 20),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
              child: Text(equipment.name, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerGroupIcon({
    required WorkerGroupModel group,
    required bool isLandscape,
  }) {
    return Positioned(
      top: group.y - 24, left: group.x - 24,
      child: GestureDetector(
        onTap: () {
          if (isLandscape) {
            setState(() => selectedWorkerGroup = group);
          } else {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => WorkerInfoSheet(zoneName: group.zoneName, workerCount: group.count),
            );
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.success, width: 2),
              ),
              child: const Icon(Icons.person, color: AppTheme.success, size: 20),
            ),
            Positioned(
              top: -5, right: -5,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                child: Text("${group.count}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(WorkerGroupModel group) {
    return Positioned(
      top: 0, bottom: 0, right: 0, width: 350,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.95),
          border: const Border(left: BorderSide(color: AppTheme.border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(-5, 0))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.group, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.zoneName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => selectedWorkerGroup = null),
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: group.workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final worker = group.workers[index];
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
                          child: Text(worker.name.substring(0, 1), style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            // [수정 2] worker.role -> worker.teamName 으로 변경
                            Text("${worker.teamName} • ${worker.status}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}