import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kReleaseMode 확인용
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TokenService {
  static const String _baseUrl = "https://220.76.77.250:5003";
  static const String _tokenEndpoint = "/api/v1/push";

  Future<void> syncTokenToServer({required String accessToken}) async {
    try {
      // 1. FCM 토큰 및 기기 정보 가져오기
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      Map<String, String> deviceData = await _getDeviceInfo();
      String appVersion = await _getAppVersion();

      // 2. 바디 구성
      Map<String, dynamic> requestBody = {
        "platform": Platform.isAndroid ? "android" : "ios",
        "token": fcmToken,
        "deviceId": deviceData['deviceId'],
        "appVersion": appVersion,
      };

      print("토큰 서버 전송 시작: $requestBody");

      // 3. API 호출 시 헤더에 토큰 추가
      final response = await http.post(
        Uri.parse("$_baseUrl$_tokenEndpoint"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("토큰 서버 등록 성공");
      } else {
        // 에러 로그 좀 더 자세히 출력
        print("토큰 서버 등록 실패: ${response.statusCode} / ${response.body}");
      }
    } catch (e) {
      print("토큰 동기화 중 에러 발생: $e");
    }
  }

  /// 기기 고유 ID 및 정보 추출
  Future<Map<String, String>> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    String model = 'unknown';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // 안드로이드 고유 ID (Android 8.0+)
        deviceId = "android-${androidInfo.id}";
        model = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        // iOS 고유 ID (Vendor ID)
        deviceId = "ios-${iosInfo.identifierForVendor ?? 'unknown'}";
        model = iosInfo.utsname.machine;
      }
    } catch (e) {
      print("기기 정보 추출 실패: $e");
    }

    return {"deviceId": deviceId, "model": model};
  }

  Future<String> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
