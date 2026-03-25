import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/activity_tile.dart';
import '../../../core/services/token_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  final TokenService _tokenService = TokenService();

  final ValueNotifier<List<Map<String, dynamic>>> _notificationNotifier = ValueNotifier([]);
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _setupFcmListener();
    _syncTokenWithAuth();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _syncTokenWithAuth();
    });
  }

  @override
  void dispose() {
    _notificationNotifier.dispose();
    super.dispose();
  }

  Future<void> _syncTokenWithAuth() async {
    String? accessToken = await _storage.read(key: 'accessToken');
    if (accessToken != null && accessToken.isNotEmpty) {
      await _tokenService.syncTokenToServer(accessToken: accessToken);
    }
  }

  Future<void> _requestPermission() async {
    FirebaseMessaging.instance.requestPermission();
  }

  void _setupFcmListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      String title = notification?.title ?? message.data['title'] ?? "System Alert";
      String body = notification?.body ?? message.data['body'] ?? "No details provided";

      if (message.data.containsKey('sensorSerialNumber')) {
        body += " (Sensor: ${message.data['sensorSerialNumber']})";
      }

      String type = message.data['type'] ?? "INFO";

      _addNewNotification(title, body, type);

      _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Emergency Alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  void _addNewNotification(String title, String body, String type) {
    final currentList = List<Map<String, dynamic>>.from(_notificationNotifier.value);

    currentList.insert(0, {
      "time": "Just now",
      "badge": type,
      "desc": title,
      "loc": body,
      "alarm": true,
    });

    if (currentList.length > 50) currentList.removeLast();

    _notificationNotifier.value = currentList;

    setState(() {
      _unreadCount++;
    });
  }

  void _showNotificationSheet() {
    setState(() {
      _unreadCount = 0;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // 다크 모드 배경색
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // 핸들바
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              const SizedBox(height: 12),

              // 헤더 레이아웃: Row + Expanded로 겹침 방지 및 정렬
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // 1. 왼쪽: 버튼 크기만큼의 빈 공간 (균형 맞추기용)
                    const SizedBox(width: 70),

                    // 2. 중앙: 제목 (남은 공간 차지 및 가운데 정렬)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Notifications",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                      ),
                    ),

                    // 3. 오른쪽: Clear All 버튼 (고정 폭)
                    SizedBox(
                      width: 70,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _notificationNotifier.value = [];
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Clear All", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              const Divider(height: 1, thickness: 0.5, color: Colors.white24),
              const SizedBox(height:10,),

              // 리스트 영역
              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _notificationNotifier,
                  builder: (context, history, child) {
                    if (history.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            "No new notifications",
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: history.length,
                      // [수정된 부분] 구분선(Divider) 위아래에 SizedBox로 여백 추가
                      separatorBuilder: (context, index) => Column(
                        children: [
                          const SizedBox(height: 10), // 👆 구분선 위쪽 여백
                          const Divider(
                            color: Colors.white12,
                            height: 1,
                            thickness: 0.5,
                          ),
                          const SizedBox(height: 10), // 👇 구분선 아래쪽 여백
                        ],
                      ),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Container(
                          color: Colors.transparent,
                          // 아이템 자체 패딩은 터치 영역 확보를 위해 유지 (필요 시 조절)
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: ActivityTile(
                            time: item['time'],
                            badgeText: item['badge'],
                            desc: item['desc'],
                            location: item['loc'],
                            isAlarm: item['alarm'],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Innosafe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text('$_unreadCount'),
                backgroundColor: AppTheme.danger,
                child: const Icon(Icons.notifications_outlined, size: 28, color: Colors.white),
              ),
              onPressed: _showNotificationSheet,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety Score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Overall Safety Score", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("97", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                      Column(
                        children: [
                          Icon(Icons.shield, color: Colors.white, size: 32),
                          Text("SAFE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: const [
                StatCard(title: "Active Workers", value: "142", icon: Icons.people, iconColor: AppTheme.success),
                StatCard(title: "Vehicles", value: "8", icon: Icons.local_shipping, iconColor: AppTheme.warning),
                StatCard(title: "Risk Alerts", value: "3", icon: Icons.warning, iconColor: AppTheme.danger, isAlert: true),
                StatCard(title: "Sensors", value: "24/24", icon: Icons.sensors, iconColor: AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}