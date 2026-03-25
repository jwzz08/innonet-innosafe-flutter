import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../../../../core/theme/app_theme.dart';

/// ========================================================================
/// VLC RTSP Player Widget
/// flutter_vlc_player 패키지 사용
/// ========================================================================
class VlcRtspPlayer extends StatefulWidget {
  final List<String> rtspUrls;
  final String deviceName;

  const VlcRtspPlayer({
    super.key,
    required this.rtspUrls,
    required this.deviceName,
  });

  @override
  State<VlcRtspPlayer> createState() => _VlcRtspPlayerState();
}

class _VlcRtspPlayerState extends State<VlcRtspPlayer> {
  late VlcPlayerController _vlcController;
  int _currentStreamIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _vlcController = VlcPlayerController.network(
      widget.rtspUrls[_currentStreamIndex],
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(1000),
        ]),
        rtp: VlcRtpOptions([
          '--rtsp-tcp', // TCP 사용 (UDP보다 안정적)
        ]),
      ),
    );

    _vlcController.addListener(() {
      if (mounted) {
        setState(() {
          _isLoading = !_vlcController.value.isPlaying;
        });
      }
    });
  }

  void _switchStream(int index) {
    if (index != _currentStreamIndex && index >= 0 && index < widget.rtspUrls.length) {
      setState(() {
        _currentStreamIndex = index;
        _isLoading = true;
        _errorMessage = null;
      });

      _vlcController.stop();
      _vlcController.setMediaFromNetwork(widget.rtspUrls[index]);
      _vlcController.play();
    }
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // 스트림 선택 탭
          if (widget.rtspUrls.length > 1)
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: List.generate(
                  widget.rtspUrls.length,
                      (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => _switchStream(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _currentStreamIndex == index
                              ? AppTheme.primary.withOpacity(0.3)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: _currentStreamIndex == index
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '카메라 ${index + 1}',
                            style: TextStyle(
                              color: _currentStreamIndex == index
                                  ? AppTheme.primary
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: _currentStreamIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 비디오 플레이어
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: widget.rtspUrls.length > 1
                      ? const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  )
                      : BorderRadius.circular(8),
                  child: VlcPlayer(
                    controller: _vlcController,
                    aspectRatio: 16 / 9,
                    placeholder: Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '스트림 연결 중...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  Container(
                    color: Colors.black87,
                    child: Center(
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
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}