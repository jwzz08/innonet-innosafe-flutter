import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio/io.dart';

// 1. 상태 정의 (State)
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  registering,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userName; // /users/infos의 name 필드

  AuthState({required this.status, this.errorMessage, this.userName});
}

// 2. Provider 정의
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 3. Notifier 구현
class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthNotifier() : super(AuthState(status: AuthStatus.initial)) {
    _initDio();
    checkLoginStatus();
  }

  // HTTPS와 SSL 우회 설정
  void _initDio() {
    _dio = Dio();
    _dio.options.baseUrl = 'https://220.76.77.250:5003/api/v1';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }

  Future<void> checkLoginStatus() async {
    print('토큰 유효성 확인 중...');
    final accessToken = await _storage.read(key: 'accessToken');

    if (accessToken == null || accessToken.isEmpty) {
      print('토큰 없음 → 로그인 필요');
      state = AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';
      final response = await _dio.get('/users/infos');

      if (response.statusCode == 200) {
        print('토큰 유효 → 자동 로그인');
        final userData = response.data;
        final name = userData['name'] as String? ?? '';
        state = AuthState(status: AuthStatus.authenticated, userName: name);
      } else {
        print('토큰 무효 → 로그인 필요');
        await _storage.deleteAll();
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print('검증 중 에러 (네트워크 문제 등) → 일단 로그인 화면으로');
      await _storage.deleteAll();
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // 로그인 요청
  Future<void> login(String userId, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      print('로그인 시도 API 호출 중...');
      final response = await _dio.post('/users/login', data: {
        'user_id': userId,
        'user_password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['islogined'] == true) {
          final tokenData = data['token'];
          final accessToken = tokenData['accessToken'];
          final refreshToken = tokenData['refreshToken'];

          await _storage.write(key: 'accessToken', value: accessToken);
          await _storage.write(key: 'refreshToken', value: refreshToken);

          // 사용자 이름 가져오기
          String userName = '';
          try {
            _dio.options.headers['Authorization'] = 'Bearer $accessToken';
            final userInfoRes = await _dio.get('/users/infos');
            if (userInfoRes.statusCode == 200) {
              userName = userInfoRes.data['name'] as String? ?? '';
            }
          } catch (_) {}

          state = AuthState(status: AuthStatus.authenticated, userName: userName);
          print('로그인 성공');
        } else {
          state = AuthState(
            status: AuthStatus.unauthenticated,
            errorMessage: "로그인 실패: 아이디/비밀번호를 확인하세요.",
          );
        }
      }
    } on DioException catch (e) {
      String errorMsg = "네트워크 오류가 발생했습니다.";
      print("🚨 Dio 로그인 에러: ${e.message}");

      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          errorMsg = "아이디 또는 비밀번호가 일치하지 않습니다.";
        } else {
          errorMsg = "로그인 실패 (${e.response?.statusCode})";
        }
      } else {
        errorMsg = "서버에 연결할 수 없습니다. (인터넷 상태 확인)";
      }
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: errorMsg);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  // 회원가입 요청
  Future<void> register({
    required String userId,
    required String password,
    required String name,
    String? email,
  }) async {
    state = AuthState(status: AuthStatus.registering);
    try {
      final response = await _dio.post('/users/regist', data: {
        'user_id': userId,
        'user_password': password,
        'user_name': name,
        if (email != null) 'user_email': email,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('회원가입 성공');
        state = AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: "회원가입 실패: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      String errorMsg = "네트워크 오류가 발생했습니다.";
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          errorMsg = data['message'];
        } else if (e.response?.statusCode == 409) {
          errorMsg = "이미 사용 중인 아이디입니다.";
        } else {
          errorMsg = "회원가입 실패 (${e.response?.statusCode})";
        }
      }
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: errorMsg);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  void forceLogout() {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: "세션이 만료되었습니다. 다시 로그인해주세요.",
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = AuthState(status: AuthStatus.unauthenticated);
    print('로그아웃');
  }
}