import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/map_icon_factory.dart';
import '../../data/repository/site_repository.dart';
import '../../data/model/dashboard_models.dart';
import '../../data/model/position_models.dart';
import '../widgets/multi_channel_rtsp_viewer.dart';
import '../widgets/vlc_rtsp_player.dart';
import '../../data/model/site_device_model.dart';

/// ========================================================================
/// Site Structure Tab - 웹 좌표계 호환
/// ========================================================================
class SiteStructureSideTab extends ConsumerStatefulWidget {
  final int siteId;
  final int? dashboardId; // ✅ 외부에서 주입 (SiteDetailScreen에서 전달)

  const SiteStructureSideTab({super.key, required this.siteId, this.dashboardId});

  @override
  ConsumerState<SiteStructureSideTab> createState() => _SiteStructureSideTabState();
}

class _SiteStructureSideTabState extends ConsumerState<SiteStructureSideTab> {
  final TransformationController _transformController = TransformationController();
  bool _isInitialized = false;
  bool _useAutoRefresh = false;
  int? _selectedDashboardId; // 외부 주입값 또는 내부 선택값
  String _selectedImagePath = 'assets/img/id-84.png'; // ✅ 선택된 이미지 경로

  // ✅ 웹 기준 좌표계 (백엔드 계산 기준)
  static const double webBaseWidth = 2000.0;
  static const double webBaseHeight = 500.0;

  // ✅ 실제 이미지 크기 (동적 감지)
  double? _actualImageWidth;
  double? _actualImageHeight;

  // Fallback 크기
  final double _fallbackImageWidth = 2784.0;
  final double _fallbackImageHeight = 1476.0;

  Uint8List? _cachedDrawingImage;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    // ✅ 외부에서 dashboardId가 주입되면 그것을 기본값으로 사용
    _selectedDashboardId = widget.dashboardId;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadAndDetectImageSize();
  }

  @override
  void dispose() {
    _transformController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// ========================================================================
  /// 이미지 로드 및 크기 감지
  /// ========================================================================
  Future<void> _loadAndDetectImageSize() async {
    try {
      final ByteData data = await rootBundle.load(_selectedImagePath);
      final Uint8List bytes = data.buffer.asUint8List();

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      if (mounted) {
        setState(() {
          _actualImageWidth = image.width.toDouble();
          _actualImageHeight = image.height.toDouble();
          _isLoadingImage = false;
        });

        print('✅ [이미지 크기] 감지: ${_actualImageWidth}×${_actualImageHeight}');
        print('📐 [웹 기준 크기] $webBaseWidth×$webBaseHeight');
        print('🔄 [비율] Width: ${(_actualImageWidth! / webBaseWidth).toStringAsFixed(3)}x, '
            'Height: ${(_actualImageHeight! / webBaseHeight).toStringAsFixed(3)}x');
      }

      image.dispose();
    } catch (e) {
      print('⚠️ [이미지 감지 실패] Fallback 사용: $e');

      if (mounted) {
        setState(() {
          _actualImageWidth = _fallbackImageWidth;
          _actualImageHeight = _fallbackImageHeight;
          _isLoadingImage = false;
        });
      }
    }
  }

  /// ========================================================================
  /// 이미지 선택 다이얼로그
  /// ========================================================================
  void _showImageSelector() {
    final availableImages = [
      {'path': 'assets/img/id-76.png', 'name': 'ID-76'},
      {'path': 'assets/img/id-83.png', 'name': 'ID-83'},
      {'path': 'assets/img/id-84.png', 'name': 'ID-84'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.image, color: AppTheme.primary, size: 24),
            SizedBox(width: 12),
            Text('도면 이미지 선택', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableImages.map((img) {
            final isSelected = _selectedImagePath == img['path'];
            return ListTile(
              leading: Icon(
                Icons.image,
                color: isSelected ? AppTheme.primary : Colors.white54,
              ),
              title: Text(
                img['name'] as String,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedImagePath = img['path'] as String;
                  _isLoadingImage = true;
                });
                Navigator.pop(context);
                _loadAndDetectImageSize();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  /// ========================================================================
  /// 최종 수정 버전 - _buildFilteredTableListSection
  /// 숫자 부분만 추출해서 비교
  /// ========================================================================
  Widget _buildFilteredTableListSection(
      List<TableItemModel> tableList,
      String targetSerialNumber,
      ) {
    print('🔍 [DEBUG] tableList.length: ${tableList.length}');
    print('🔍 [DEBUG] targetSerialNumber: $targetSerialNumber');

    // ✅ 숫자 부분만 추출해서 비교
    String extractNumbers(String serial) {
      // 숫자만 남기고 나머지 제거
      // 예: "BR1-001203" → "1001203", "SN-001203" → "001203"
      return serial.replaceAll(RegExp(r'[^0-9]'), '');
    }

    final targetNumbers = extractNumbers(targetSerialNumber);
    print('🔍 [DEBUG] targetNumbers: $targetNumbers');

    final filteredList = tableList.where((item) {
      if (item.serialNumber == null) return false;

      final itemNumbers = extractNumbers(item.serialNumber!);

      // 숫자가 같거나 포함하는지 확인
      final match = itemNumbers == targetNumbers ||
          itemNumbers.contains(targetNumbers) ||
          targetNumbers.contains(itemNumbers);

      print('🔍 [DEBUG] ${item.serialNumber} (숫자: $itemNumbers) ↔ $targetSerialNumber (숫자: $targetNumbers)? $match');
      return match;
    }).toList();

    print('🔍 [DEBUG] filteredList.length: ${filteredList.length}');

    if (filteredList.isEmpty) {
      return _buildInfoSection(
        title: '디바이스 정보',
        icon: Icons.devices,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '해당 시리얼 번호의 디바이스를 찾을 수 없습니다.',
                        style: TextStyle(color: AppTheme.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '찾는 S/N: $targetSerialNumber (숫자: $targetNumbers)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  '전체 디바이스: ${tableList.length}개',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _buildInfoSection(
      title: '디바이스 정보 (${filteredList.length}개)',
      icon: Icons.devices,
      children: filteredList.map((item) =>
          GestureDetector(
            onTap: () {
              // ✅ deviceId가 null이면 id를 사용
              final deviceIdToUse = item.deviceId ?? item.id;
              print('🔍 [DEBUG] 디바이스 클릭: ${item.name}, deviceId: $deviceIdToUse');
              _showDeviceDetail(item, deviceIdToUse);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    item.type.toLowerCase() == 'ble'
                        ? Icons.bluetooth
                        : Icons.router,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.serialNumber != null)
                          Text(
                            'S/N: ${item.serialNumber}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (item.humanCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.humanCount}명',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ).toList(),
    );
  }

  Future<void> _showDeviceDetail(TableItemModel device, int deviceId) async {
    print('🔍 [DEBUG] _showDeviceDetail 호출: deviceId=$deviceId');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AppTheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (device.serialNumber != null)
                            Text(
                              'S/N: ${device.serialNumber}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 콘텐츠 (RTSP 스트림 로딩)
              Expanded(
                child: FutureBuilder<DeviceDetailModel>(
                  future: ref
                      .read(dashboardRepositoryProvider)
                      .fetchDeviceDetail(deviceId),
                  builder: (context, snapshot) {
                    // ✅ 로그 추가
                    print('🔍 [DEBUG] FutureBuilder state: ${snapshot.connectionState}');

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('🔍 [DEBUG] API 호출 대기 중...');
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      // ✅ 에러 로그 추가
                      print('❌ [ERROR] API 호출 실패: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.danger,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '디바이스 정보를 불러올 수 없습니다.',
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final deviceDetail = snapshot.data!;

                    // ✅ 디바이스 상세 정보 로그
                    print('✅ [SUCCESS] Device Detail 로드 성공');
                    print('🔍 [DEBUG] Device: ${deviceDetail.name}');
                    print('🔍 [DEBUG] Device Type: ${deviceDetail.deviceType}');
                    print('🔍 [DEBUG] RTSP List 개수: ${deviceDetail.properties.rtspList.length}');
                    print('🔍 [DEBUG] hasRtspStreams: ${deviceDetail.properties.hasRtspStreams}');

                    if (deviceDetail.properties.rtspList.isNotEmpty) {
                      print('🔍 [DEBUG] RTSP URLs:');
                      for (var i = 0; i < deviceDetail.properties.rtspList.length; i++) {
                        print('  [$i] ${deviceDetail.properties.rtspList[i]}');
                      }
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 기본 정보
                          _buildInfoSection(
                            title: '기본 정보',
                            icon: Icons.info_outline,
                            children: [
                              _buildInfoRow('타입', deviceDetail.deviceType),
                              _buildInfoRow('모델', deviceDetail.deviceModel),
                              if (deviceDetail.location != null)
                                _buildInfoRow('위치', deviceDetail.location!),
                              _buildInfoRow(
                                '상태',
                                deviceDetail.status,
                                valueColor: deviceDetail.status == 'Normal'
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                              if (deviceDetail.properties.mode != null)
                                _buildInfoRow(
                                  '모드',
                                  deviceDetail.properties.mode!,
                                ),
                            ],
                          ),

                          // RTSP 스트림 정보
                          if (deviceDetail.properties.hasRtspStreams) ...[
                            const SizedBox(height: 20),
                            // ✅ VLC Player 렌더링 로그
                            Builder(
                              builder: (context) {
                                print('🎥 [DEBUG] VLC Player 렌더링 시작');
                                return _buildInfoSection(
                                  title: '카메라 스트림',
                                  icon: Icons.videocam,
                                  children: [
                                    VlcRtspPlayer(
                                      rtspUrls: deviceDetail.properties.rtspList,
                                      deviceName: deviceDetail.name,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ] else ...[
                            // ✅ RTSP가 없을 때 로그
                            const SizedBox(height: 20),
                            Builder(
                              builder: (context) {
                                print('⚠️ [WARNING] hasRtspStreams = false, VLC Player 표시 안 됨');
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '이 디바이스에는 카메라 스트림이 없습니다.',
                                          style: TextStyle(color: AppTheme.warning, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          // 네트워크 정보
                          if (deviceDetail.properties.publicIp != null ||
                              deviceDetail.properties.port != null) ...[
                            const SizedBox(height: 20),
                            _buildInfoSection(
                              title: '네트워크 정보',
                              icon: Icons.network_check,
                              children: [
                                if (deviceDetail.properties.publicIp != null)
                                  _buildInfoRow(
                                    'Public IP',
                                    deviceDetail.properties.publicIp!,
                                  ),
                                if (deviceDetail.properties.port != null)
                                  _buildInfoRow(
                                    'Port',
                                    deviceDetail.properties.port.toString(),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingImage) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('이미지 분석 중...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    // ✅ 외부에서 dashboardId가 주입된 경우 → 바로 구조 뷰 표시
    if (widget.dashboardId != null) {
      final effectiveDashboardId = _selectedDashboardId ?? widget.dashboardId!;
      return Column(
        children: [
          // 이미지 선택 + 자동갱신 토글만 남김
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 이미지 선택 버튼
                IconButton(
                  icon: const Icon(Icons.image, color: AppTheme.primary, size: 20),
                  tooltip: '도면 이미지 선택',
                  onPressed: () => _showImageSelector(),
                ),
                // 자동 갱신 토글
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.autorenew,
                      size: 18,
                      color: _useAutoRefresh ? AppTheme.success : Colors.white38,
                    ),
                    Switch(
                      value: _useAutoRefresh,
                      activeColor: AppTheme.success,
                      onChanged: (value) {
                        setState(() => _useAutoRefresh = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildStructureView(effectiveDashboardId)),
        ],
      );
    }

    // ✅ 외부 dashboardId 없는 경우 (기존 fallback: 목록에서 선택)
    final dashboardListAsync = ref.watch(dashboardListProvider(widget.siteId));

    return dashboardListAsync.when(
      data: (dashboards) {
        if (dashboards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard_outlined, size: 64, color: Colors.white38),
                SizedBox(height: 16),
                Text('등록된 Dashboard가 없습니다.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        final selectedDashboardId = _selectedDashboardId ?? dashboards.first.id;

        // ✅ 첫 진입 시 기본값 설정
        if (_selectedDashboardId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedDashboardId = dashboards.first.id);
          });
        }

        final selectedDashboard = dashboards.firstWhere(
              (d) => d.id == selectedDashboardId,
          orElse: () => dashboards.first,
        );

        return Column(
          children: [
            // Dashboard 선택 드롭다운 제거됨 (SiteDetailScreen AppBar에서 처리)
            // 이미지 선택 + 자동갱신 토글만 유지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 이미지 선택 버튼
                  IconButton(
                    icon: const Icon(Icons.image, color: AppTheme.primary, size: 20),
                    tooltip: '도면 이미지 선택',
                    onPressed: () => _showImageSelector(),
                  ),
                  // 자동 갱신 토글
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 18,
                        color: _useAutoRefresh ? AppTheme.success : Colors.white38,
                      ),
                      Switch(
                        value: _useAutoRefresh,
                        activeColor: AppTheme.success,
                        onChanged: (value) {
                          setState(() => _useAutoRefresh = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(child: _buildStructureView(selectedDashboardId)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        return _buildErrorView(
          'Dashboard 로드 실패',
          error.toString(),
              () => ref.invalidate(dashboardListProvider),
        );
      },
    );
  }

  Widget _buildStructureView(int dashboardId) {
    final params = EnrichedStructureParams(
      siteGroupId: widget.siteId,
      dashboardId: dashboardId,
    );

    if (_useAutoRefresh) {
      return _buildAutoRefreshView(params);
    } else {
      return _buildNormalView(params);
    }
  }

  Widget _buildNormalView(EnrichedStructureParams params) {
    final structureAsync = ref.watch(enrichedStructureProvider(params));

    return structureAsync.when(
      data: (structure) => _buildMapContent(structure),
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(
        '도면 로드 실패',
        error.toString(),
            () => ref.invalidate(enrichedStructureProvider),
      ),
    );
  }

  Widget _buildAutoRefreshView(EnrichedStructureParams params) {
    final dashboardAsync = ref.watch(dashboardDetailProvider(params.dashboardId));
    final positionStreamAsync = ref.watch(autoRefreshPositionProvider(params.siteGroupId));

    return dashboardAsync.when(
      data: (dashboard) {
        final siteImageWidget = dashboard.siteImageWidgets.firstOrNull;

        if (siteImageWidget == null || siteImageWidget.siteImageProperties == null) {
          final defaultWidget = DashboardWidgetModel(
            id: 0,
            type: 'site_image',
            x: 0,
            y: 0,
            w: 16,
            h: 7,
            properties: {},
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            dashboardId: params.dashboardId,
            siteImageProperties: SiteImageProperties(
              iconList: [],
              tableList: [],
              deviceRemoveList: [],
            ),
          );

          return positionStreamAsync.when(
            data: (positions) {
              final structure = StructureViewModel(
                dashboard: dashboard,
                widget: defaultWidget,
                enrichedIcons: [],
                tableList: [],
                deviceRemoveList: [],
                totalWorkerCount: positions.getTotalCount(),
                positions: positions,
              );
              return _buildMapContent(structure);
            },
            loading: () => _buildMapContent(
              StructureViewModel(
                dashboard: dashboard,
                widget: defaultWidget,
                enrichedIcons: [],
                tableList: [],
                deviceRemoveList: [],
                totalWorkerCount: 0,
                positions: PositionAggregation(workerCountByReader: {}, workerById: {}),
              ),
            ),
            error: (error, stack) => _buildMapContent(
              StructureViewModel(
                dashboard: dashboard,
                widget: defaultWidget,
                enrichedIcons: [],
                tableList: [],
                deviceRemoveList: [],
                totalWorkerCount: 0,
                positions: PositionAggregation(workerCountByReader: {}, workerById: {}),
              ),
            ),
          );
        }

        return positionStreamAsync.when(
          data: (positions) {
            final props = siteImageWidget.siteImageProperties!;
            final enrichedIcons = props.iconList.map((icon) {
              int liveCount = icon.humanCount;
              if (icon.serialNumber != null && icon.serialNumber!.isNotEmpty) {
                liveCount = positions.getCountForReader(icon.serialNumber!);
              }
              return IconViewModel(original: icon, liveHumanCount: liveCount);
            }).toList();

            final structure = StructureViewModel(
              dashboard: dashboard,
              widget: siteImageWidget,
              enrichedIcons: enrichedIcons,
              tableList: props.tableList,
              deviceRemoveList: props.deviceRemoveList,
              totalWorkerCount: positions.getTotalCount(),
              positions: positions,
            );

            return _buildMapContent(structure);
          },
          loading: () => _buildMapContent(
            StructureViewModel(
              dashboard: dashboard,
              widget: siteImageWidget,
              enrichedIcons: siteImageWidget.siteImageProperties!.iconList
                  .map((icon) => IconViewModel(original: icon, liveHumanCount: icon.humanCount))
                  .toList(),
              tableList: siteImageWidget.siteImageProperties!.tableList,
              deviceRemoveList: siteImageWidget.siteImageProperties!.deviceRemoveList,
              totalWorkerCount: 0,
              positions: PositionAggregation(workerCountByReader: {}, workerById: {}),
            ),
          ),
          error: (error, stack) => _buildErrorView(
            'Position 갱신 실패',
            error.toString(),
                () => ref.invalidate(autoRefreshPositionProvider),
          ),
        );
      },
      loading: () => _buildLoadingView(),
      error: (error, stack) => _buildErrorView(
        'Dashboard 로드 실패',
        error.toString(),
            () => ref.invalidate(dashboardDetailProvider),
      ),
    );
  }

  Widget _buildMapContent(StructureViewModel structure) {
    if (_cachedDrawingImage == null) {
      _loadWidgetDrawing(structure.widget.id);
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return _buildMapViewer(structure, isLandscape);
      },
    );
  }

  /// ========================================================================
  /// ✅ Map Viewer - 웹→앱 좌표 변환 적용
  /// ========================================================================
  Widget _buildMapViewer(StructureViewModel structure, bool isLandscape) {
    final imageWidth = _actualImageWidth ?? _fallbackImageWidth;
    final imageHeight = _actualImageHeight ?? _fallbackImageHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitScale = constraints.maxHeight / imageHeight;

        if (!_isInitialized) {
          _transformController.value = Matrix4.identity()..scale(fitScale);
          _isInitialized = true;
        }

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              constrained: false,
              boundaryMargin: EdgeInsets.zero,
              minScale: fitScale,
              maxScale: 4.0,
              child: SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: Stack(
                  children: [
                    // 배경 이미지
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF1A1D24),
                        child: _cachedDrawingImage != null
                            ? Image.memory(_cachedDrawingImage!, fit: BoxFit.contain)
                            : Image.asset(
                          _selectedImagePath, // ✅ 선택된 이미지 사용
                          fit: BoxFit.contain,
                          errorBuilder: (c, o, s) => const Center(
                            child: Icon(Icons.broken_image, size: 64, color: Colors.white24),
                          ),
                        ),
                      ),
                    ),

                    // ✅ 아이콘 레이어 (웹→앱 좌표 변환)
                    ...structure.enrichedIcons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final enrichedIcon = entry.value;
                      final icon = enrichedIcon.original;

                      // ✅ 1단계: Percent → 웹 기준 픽셀
                      final webX = (icon.xPercent / 100) * webBaseWidth;
                      final webY = (icon.yPercent / 100) * webBaseHeight;

                      // ✅ 2단계: 웹 픽셀 → 앱 픽셀 (비율 변환)
                      final appX = (webX / webBaseWidth) * imageWidth;
                      final appY = (webY / webBaseHeight) * imageHeight;

                      if (index == 0) {
                        print('🎨 [좌표 변환] Icon[0]: ${icon.name}');
                        print('   1️⃣ Backend Percent: (${icon.xPercent.toStringAsFixed(2)}%, ${icon.yPercent.toStringAsFixed(2)}%)');
                        print('   2️⃣ Web Pixel: ($webX, $webY) [기준: ${webBaseWidth}×$webBaseHeight]');
                        print('   3️⃣ App Pixel: ($appX, $appY) [실제: ${imageWidth}×$imageHeight]');
                      }

                      return MapIconFactory.buildIcon(
                        icon: icon,
                        humanCount: enrichedIcon.liveHumanCount,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                        onTap: () => _handleIconTap(enrichedIcon, structure, isLandscape),
                      );
                    }),
                  ],
                ),
              ),
            ),

            if (!isLandscape)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'reset_view',
                  backgroundColor: AppTheme.surface.withOpacity(0.8),
                  child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                  onPressed: () {
                    final fitScale = constraints.maxHeight / imageHeight;
                    _transformController.value = Matrix4.identity()..scale(fitScale);
                  },
                ),
              ),

            if (!isLandscape)
              Positioned(
                bottom: 80,
                right: 70,
                child: FloatingActionButton.small(
                  heroTag: 'landscape_btn',
                  backgroundColor: AppTheme.surfaceHighlight.withOpacity(0.9),
                  child: const Icon(Icons.screen_rotation_rounded, color: Colors.white),
                  onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]),
                ),
              ),

            if (isLandscape)
              Positioned(
                top: 24,
                left: 24,
                child: SafeArea(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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

  void _handleIconTap(IconViewModel enrichedIcon, StructureViewModel structure, bool isLandscape) {
    final icon = enrichedIcon.original;
    print('👆 [DEBUG] Icon 탭: ${icon.name} (type: ${icon.type})');

    if (isLandscape) {
      _showSidePanel(enrichedIcon, structure);
    } else {
      _showIconDetailDialog(enrichedIcon, structure);
    }
  }

  /// ========================================================================
  /// _buildCameraSection 함수 (완전한 코드)
  /// 이 함수를 복사해서 기존 _buildCameraSection을 완전히 교체하세요
  /// ========================================================================

  Widget _buildCameraSection(
      List<int> deviceIds,
      List<SiteDeviceModel> allDevices,
      String locationName,
      ) {
    // ✅ devices 리스트에서 직접 RTSP 정보 추출 (동기적 처리)
    final List<DeviceRtspInfo> devicesWithRtsp = [];

    for (final deviceId in deviceIds) {
      try {
        final device = allDevices.firstWhere(
              (d) => d.id == deviceId,
          orElse: () => throw Exception('Device $deviceId not found'),
        );

        if (device.properties.hasRtspStreams) {
          devicesWithRtsp.add(DeviceRtspInfo(
            deviceName: device.name,
            deviceType: device.name.contains('BLE') ? 'BLE' : 'TVWS',
            rtspUrls: device.properties.rtspList,
          ));
        }
      } catch (e) {
        print('⚠️ Device $deviceId 처리 중 오류: $e');
      }
    }

    // RTSP 정보가 없는 경우
    if (devicesWithRtsp.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '이 위치에는 카메라가 설치되지 않았습니다.',
                style: const TextStyle(color: AppTheme.warning, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // RTSP 정보가 있는 경우
    return _buildInfoSection(
      title: '카메라 스트림',
      icon: Icons.videocam,
      children: [
        MultiChannelRtspViewer(
          devices: devicesWithRtsp,
          locationName: locationName,
        ),
      ],
    );
  }

  /// ========================================================================
  /// Site Devices에서 직접 RTSP 정보 추출 (API 호출 불필요)
  /// ========================================================================
  Future<List<DeviceRtspInfo>> _fetchDeviceRtspInfoFromList(
      List<int> deviceIds,
      List<SiteDeviceModel> allDevices,
      ) async {
    print('🎥 [FetchRTSP] deviceIds: $deviceIds');

    final List<DeviceRtspInfo> result = [];

    for (final deviceId in deviceIds) {
      try {
        // devices 리스트에서 해당 device 찾기
        final device = allDevices.firstWhere(
              (d) => d.id == deviceId,
          orElse: () => throw Exception('Device $deviceId not found'),
        );

        print('  📌 Device $deviceId: ${device.name}');

        // RTSP가 있으면 추가
        if (device.properties.hasRtspStreams) {
          result.add(DeviceRtspInfo(
            deviceName: device.name,
            deviceType: device.name.contains('BLE') ? 'BLE' : 'TVWS',
            rtspUrls: device.properties.rtspList,
          ));

          print('    ✅ RTSP 발견: ${device.properties.rtspList.length}개');
        } else {
          print('    ⚠️ RTSP 없음');
        }
      } catch (e) {
        print('    ❌ 에러: $e');
      }
    }

    print('🎥 [FetchRTSP] 총 ${result.length}개 디바이스에서 RTSP 발견');
    return result;
  }

  /// ========================================================================
  /// 디버깅용 _showIconDetailDialog
  /// deviceIds 확인 로그 추가
  /// ========================================================================

  void _showIconDetailDialog(IconViewModel enrichedIcon, StructureViewModel structure) {
    final icon = enrichedIcon.original;
    final siteGroupId = structure.dashboard.siteGroupId;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // ✅ Site의 모든 devices 가져오기
          final devicesAsync = ref.watch(siteDevicesProvider(siteGroupId));

          return devicesAsync.when(
            data: (devices) {
              // serialNumber로 deviceId 매칭
              final deviceIds = <int>[];

              print('');
              print('🔍 [POPUP] 아이콘 팝업 열림');
              print('  📌 name: ${icon.name}');
              print('  📌 type: ${icon.type}');
              print('  📌 serialNumber: ${icon.serialNumber}');
              print('  📌 Total devices in site: ${devices.length}');

              if (icon.serialNumber != null && icon.serialNumber!.isNotEmpty) {
                String extractNumbers(String serial) {
                  return serial.replaceAll(RegExp(r'[^0-9]'), '');
                }

                final targetNumbers = extractNumbers(icon.serialNumber!);
                print('  🔎 targetNumbers: "$targetNumbers"');

                for (var device in devices) {
                  final deviceNumbers = extractNumbers(device.serialNumber);
                  final match = deviceNumbers == targetNumbers ||
                      deviceNumbers.contains(targetNumbers) ||
                      targetNumbers.contains(deviceNumbers);

                  if (match) {
                    deviceIds.add(device.id);
                    print('  ✅ MATCHED! Device: ${device.name}, ID: ${device.id}');
                  }
                }
              }

              print('  📌 Final deviceIds: $deviceIds');
              print('');

              // 다이얼로그 UI 빌드
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIconTypeIcon(icon.type), color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    icon.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${icon.type} · ${enrichedIcon.liveHumanCount}명',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),

                      // 콘텐츠
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 기본 정보
                              _buildInfoSection(
                                title: '기본 정보',
                                icon: Icons.info_outline,
                                children: [
                                  _buildInfoRow('현재 인원', '${enrichedIcon.liveHumanCount}명',
                                      valueColor: enrichedIcon.liveHumanCount > 0 ? AppTheme.success : Colors.white70),
                                  if (icon.serialNumber != null)
                                    _buildInfoRow('Serial Number', icon.serialNumber!),
                                  _buildInfoRow('Device IDs', deviceIds.isEmpty ? '없음' : deviceIds.join(', ')),
                                ],
                              ),

                              // ✅ 카메라 섹션
                              if (deviceIds.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildCameraSection(deviceIds, devices, icon.name),
                              ],

                              // 작업자 상세 (BLE일 때)
                              if ((icon.type.toLowerCase() == 'ble' || icon.type.toLowerCase() == 'blesum') &&
                                  icon.serialNumber != null &&
                                  icon.serialNumber!.isNotEmpty &&
                                  enrichedIcon.liveHumanCount > 0) ...[
                                const SizedBox(height: 20),
                                _buildWorkerDetailSection(icon.serialNumber!, structure.positions),
                              ],

                              // 굴진율 정보
                              if (icon.type.toLowerCase() == 'excavationrate') ...[
                                const SizedBox(height: 20),
                                _buildInfoSection(
                                  title: '굴진율 정보',
                                  icon: Icons.show_chart,
                                  children: [
                                    _buildInfoRow('진행률', '${icon.progressValue.toStringAsFixed(1)}%',
                                        valueColor: AppTheme.success),
                                    if (icon.title.isNotEmpty)
                                      _buildInfoRow('제목', icon.title),
                                  ],
                                ),
                              ],

                              // 장비 목록
                              if (icon.type.toLowerCase() == 'equipmentsum' && icon.equipmentNames.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildInfoSection(
                                  title: '장비 목록',
                                  icon: Icons.construction,
                                  children: icon.equipmentNames.map((name) =>
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                                            const SizedBox(width: 8),
                                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                  ).toList(),
                                ),
                              ],

                              // 자재 목록
                              if (icon.type.toLowerCase() == 'materialsum' && icon.materialNames.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildInfoSection(
                                  title: '자재 목록',
                                  icon: Icons.inventory_2,
                                  children: icon.materialNames.map((name) =>
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                                            const SizedBox(width: 8),
                                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                  ).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => Dialog(
              backgroundColor: AppTheme.surface,
              child: Container(
                padding: const EdgeInsets.all(40),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 20),
                    Text('장치 정보 로딩 중...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            error: (error, stack) => Dialog(
              backgroundColor: AppTheme.surface,
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                    const SizedBox(height: 20),
                    Text('오류: $error', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSidePanel(IconViewModel enrichedIcon, StructureViewModel structure) {
    final icon = enrichedIcon.original;
    final siteGroupId = structure.dashboard.siteGroupId;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Consumer(
            builder: (context, ref, child) {
              // ✅ Site의 모든 devices 가져오기
              final devicesAsync = ref.watch(siteDevicesProvider(siteGroupId));

              return devicesAsync.when(
                data: (devices) {
                  // serialNumber로 deviceId 매칭
                  final deviceIds = <int>[];

                  if (icon.serialNumber != null && icon.serialNumber!.isNotEmpty) {
                    String extractNumbers(String serial) {
                      return serial.replaceAll(RegExp(r'[^0-9]'), '');
                    }

                    final targetNumbers = extractNumbers(icon.serialNumber!);

                    for (var device in devices) {
                      final deviceNumbers = extractNumbers(device.serialNumber);
                      final match = deviceNumbers == targetNumbers ||
                          deviceNumbers.contains(targetNumbers) ||
                          targetNumbers.contains(deviceNumbers);

                      if (match) {
                        deviceIds.add(device.id);
                      }
                    }
                  }

                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 400,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 헤더
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              border: const Border(bottom: BorderSide(color: AppTheme.border)),
                            ),
                            child: Row(
                              children: [
                                Icon(_getIconTypeIcon(icon.type), color: AppTheme.primary, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        icon.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${enrichedIcon.liveHumanCount}명',
                                        style: const TextStyle(color: AppTheme.success, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white70),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),

                          // 콘텐츠
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoSection(
                                    title: '기본 정보',
                                    icon: Icons.info_outline,
                                    children: [
                                      _buildInfoRow('현재 인원', '${enrichedIcon.liveHumanCount}명',
                                          valueColor: enrichedIcon.liveHumanCount > 0 ? AppTheme.success : Colors.white70),
                                      if (icon.serialNumber != null)
                                        _buildInfoRow('Serial Number', icon.serialNumber!),
                                      _buildInfoRow('Device IDs', deviceIds.isEmpty ? '없음' : deviceIds.join(', ')),
                                    ],
                                  ),

                                  // ✅ 카메라 섹션
                                  if (deviceIds.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    _buildCameraSection(deviceIds, devices, icon.name),
                                  ],

                                  if (icon.serialNumber != null && enrichedIcon.liveHumanCount > 0) ...[
                                    const SizedBox(height: 20),
                                    _buildWorkerDetailSection(icon.serialNumber!, structure.positions),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 400,
                    color: AppTheme.surface,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
                ),
                error: (error, stack) => Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 400,
                    color: AppTheme.surface,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                          const SizedBox(height: 20),
                          Text('오류 발생', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  // 정보 섹션 빌더
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighlight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

// 작업자 상세 정보 섹션
  Widget _buildWorkerDetailSection(String serialNumber, PositionAggregation positions) {
    final workers = positions.workerById.values.where(
          (worker) => worker.position.readerSerial == serialNumber,
    ).toList();

    if (workers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildInfoSection(
      title: '현재 작업자 (${workers.length}명)',
      icon: Icons.people,
      children: workers.map((worker) =>
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      worker.workerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (worker.teamName != null)
                  Text('팀: ${worker.teamName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (worker.workerPhoneNumber != null)
                  Text('연락처: ${worker.workerPhoneNumber}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (worker.workerAge != null)
                  Text('나이: ${worker.workerAge}세', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
      ).toList(),
    );
  }

// TableList 섹션
  Widget _buildTableListSection(List<TableItemModel> tableList) {
    return _buildInfoSection(
      title: '전체 디바이스 (${tableList.length}개)',
      icon: Icons.devices,
      children: tableList.map((item) =>
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  item.type.toLowerCase() == 'ble' ? Icons.bluetooth : Icons.router,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (item.serialNumber != null)
                        Text(
                          'S/N: ${item.serialNumber}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (item.humanCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.humanCount}명',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
      ).toList(),
    );
  }

  IconData _getIconTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ble':
        return Icons.person;
      case 'blesum':
        return Icons.groups;
      case 'totalsum':
        return Icons.people;
      case 'excavationrate':
        return Icons.show_chart;
      case 'equipmentsum':
        return Icons.construction;
      case 'materialsum':
        return Icons.inventory_2;
      case 'master':
      case 'slave':
        return Icons.router;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _loadWidgetDrawing(int widgetId) async {
    try {
      final repository = ref.read(dashboardRepositoryProvider);
      final imageData = await repository.fetchWidgetDrawing(widgetId);
      if (imageData != null && mounted) {
        // setState(() => _cachedDrawingImage = base64Decode(imageData));
      }
    } catch (e) {
      print('⚠️ Drawing 로드 실패: $e');
    }
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('도면 로딩 중...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildErrorView(String title, String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }
}