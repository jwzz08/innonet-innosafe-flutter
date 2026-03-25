import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/model/dashboard_models.dart';

/// ========================================================================
/// Multi-Channel RTSP Viewer (video_player 사용)
/// flutter_vlc_player 대신 video_player 사용
/// ========================================================================
class MultiChannelRtspViewer extends StatefulWidget {
  final List<DeviceRtspInfo> devices;
  final String locationName;

  const MultiChannelRtspViewer({
    super.key,
    required this.devices,
    required this.locationName,
  });

  @override
  State<MultiChannelRtspViewer> createState() => _MultiChannelRtspViewerState();
}

class _MultiChannelRtspViewerState extends State<MultiChannelRtspViewer> {
  VideoPlayerController? _controller;
  int? _currentChannelIndex;
  bool _isLoading = false;
  String? _errorMessage;

  List<ChannelInfo> _allChannels = [];

  @override
  void initState() {
    super.initState();
    _buildChannelList();
  }

  void _buildChannelList() {
    _allChannels = [];

    for (var device in widget.devices) {
      for (var i = 0; i < device.rtspUrls.length; i++) {
        _allChannels.add(ChannelInfo(
          deviceName: device.deviceName,
          deviceType: device.deviceType,
          channelNumber: i + 1,
          rtspUrl: device.rtspUrls[i],
        ));
      }
    }

    print('🎥 [VideoPlayer] 총 ${_allChannels.length}개 채널 준비');
  }

  Future<void> _loadChannel(int index) async {
    if (index < 0 || index >= _allChannels.length) return;

    final channel = _allChannels[index];
    print('');
    print('🎥 [VideoPlayer] 채널 로드');
    print('  Device: ${channel.deviceName}');
    print('  Channel: ${channel.channelNumber}');
    print('  URL: ${channel.rtspUrl}');

    setState(() {
      _currentChannelIndex = index;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 기존 컨트롤러 정리
      if (_controller != null) {
        await _controller!.pause();
        await _controller!.dispose();
        _controller = null;
      }

      // 새 컨트롤러 생성
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(channel.rtspUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // 초기화
      await _controller!.initialize();

      // 재생 시작
      await _controller!.play();

      print('  ✅ 채널 로드 성공');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('  ❌ 채널 로드 실패: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'RTSP 연결 실패: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allChannels.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          if (_currentChannelIndex != null) _buildHeader(),
          Container(
            height: 280,
            color: Colors.black,
            child: _currentChannelIndex == null
                ? _buildSelectPrompt()
                : _buildVideoArea(),
          ),
          _buildChannelSelector(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              '카메라 스트림 정보가 없습니다.',
              style: TextStyle(color: AppTheme.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final channel = _allChannels[_currentChannelIndex!];
    final isPlaying = _controller?.value.isPlaying ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            channel.deviceType.toLowerCase() == 'ble'
                ? Icons.bluetooth
                : Icons.router,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '채널 ${channel.channelNumber}',
                  style: TextStyle(
                    color: AppTheme.primary.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPlaying
                  ? AppTheme.success.withOpacity(0.2)
                  : AppTheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPlaying ? AppTheme.success : AppTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaying ? Icons.play_circle_filled : Icons.pause_circle,
                  color: isPlaying ? AppTheme.success : Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isPlaying ? '재생 중' : '대기',
                  style: TextStyle(
                    color: isPlaying ? AppTheme.success : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            '아래에서 채널을 선택하세요',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_allChannels.length}개 채널 사용 가능',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_isLoading || _controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'RTSP 스트림 연결 중...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentChannelIndex != null) {
                  _loadChannel(_currentChannelIndex!);
                }
              },
              icon: Icon(Icons.refresh),
              label: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildChannelSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topLeft: _currentChannelIndex == null ? Radius.circular(8) : Radius.zero,
          topRight: _currentChannelIndex == null ? Radius.circular(8) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.video_library, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '채널 선택',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_allChannels.length, (index) {
              final channel = _allChannels[index];
              final isSelected = index == _currentChannelIndex;

              return GestureDetector(
                onTap: _isLoading ? null : () => _loadChannel(index),
                child: Opacity(
                  opacity: _isLoading ? 0.5 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam,
                          color: isSelected ? Colors.white : Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.deviceName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '채널 ${channel.channelNumber}',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// ========================================================================
/// Helper Classes
/// ========================================================================

class DeviceRtspInfo {
  final String deviceName;
  final String deviceType;
  final List<String> rtspUrls;

  DeviceRtspInfo({
    required this.deviceName,
    required this.deviceType,
    required this.rtspUrls,
  });
}

class ChannelInfo {
  final String deviceName;
  final String deviceType;
  final int channelNumber;
  final String rtspUrl;

  ChannelInfo({
    required this.deviceName,
    required this.deviceType,
    required this.channelNumber,
    required this.rtspUrl,
  });
}