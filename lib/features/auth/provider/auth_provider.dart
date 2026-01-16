import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

// 1. 상태 정의 (State)
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});
}

// 2. Provider 정의
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 3. Notifier 구현
class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  AuthNotifier() : super(AuthState(status: AuthStatus.initial)) {
    _dio.options.baseUrl = 'http://220.76.77.250:5003/api/v1';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    checkLoginStatus();
  }

  // 앱 시작 시 토큰 유무 확인 (자동 로그인)
  Future<void> checkLoginStatus() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      state = AuthState(status: AuthStatus.authenticated);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // 로그인 요청
  Future<void> login(String userId, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      // API 문서 6.1.2 참조: POST /users/login
      final response = await _dio.post('/users/login', data: {
        'user_id': userId,
        'user_password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // 응답 구조 확인
        if (data['islogined'] == true) {
          final tokenData = data['token'];
          final accessToken = tokenData['accessToken'];
          final refreshToken = tokenData['refreshToken'];

          // 토큰 안전 저장
          await _storage.write(key: 'accessToken', value: accessToken);
          await _storage.write(key: 'refreshToken', value: refreshToken);

          state = AuthState(status: AuthStatus.authenticated);
        } else {
          state = AuthState(status: AuthStatus.unauthenticated, errorMessage: "로그인 실패: 아이디/비밀번호를 확인하세요.");
        }
      } else {
        state = AuthState(status: AuthStatus.unauthenticated, errorMessage: "서버 오류: ${response.statusCode}");
      }
    } on DioException catch (e) {
      String errorMsg = "네트워크 오류가 발생했습니다.";
      if (e.response != null) {
        // 서버 응답이 온 경우 메시지 파싱 시도
        errorMsg = "로그인 실패 (${e.response?.statusCode})";
      }
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: errorMsg);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _storage.deleteAll();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}