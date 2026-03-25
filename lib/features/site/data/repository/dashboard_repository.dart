import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/dashboard_models.dart';

/// ========================================================================
/// Dashboard API Repository
/// ========================================================================
class DashboardRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  DashboardRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
    baseUrl: 'https://220.76.77.250:5003/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )),
        _storage = storage ?? const FlutterSecureStorage();

  /// ===================================================================
  /// 1. 특정 Site의 Dashboard 목록 조회
  /// GET /api/v1/sitegroups/{siteGroupId}/dashboards
  /// ===================================================================
  Future<List<DashboardSummaryModel>> fetchDashboardList(int siteGroupId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception('로그인 정보가 없습니다.');

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/sitegroups/$siteGroupId/dashboards');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => DashboardSummaryModel.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleError(e, 'Dashboard 목록 조회 실패');
    }
  }

  /// ===================================================================
  /// 2. Dashboard 상세 정보 조회 (iconList, tableList 포함)
  /// GET /api/v1/dashboards/{dashboardId}
  /// ===================================================================
  Future<DashboardDetailModel> fetchDashboardDetail(int dashboardId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception('로그인 정보가 없습니다.');

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/dashboards/$dashboardId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return DashboardDetailModel.fromJson(response.data);
      }

      throw Exception('Dashboard 데이터 형식 오류');
    } on DioException catch (e) {
      throw _handleError(e, 'Dashboard 상세 조회 실패');
    }
  }

  /// ===================================================================
  /// 3. Widget 배경 이미지 조회 (Base64 또는 URL)
  /// GET /api/v1/widgets/{widgetId}/drawings
  /// ===================================================================
  Future<String?> fetchWidgetDrawing(int widgetId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) return null;

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get(
        '/widgets/$widgetId/drawings',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Base64 인코딩하여 반환 (또는 임시 파일로 저장)
        // 현재는 null 반환 (추후 구현)
        return null;
      }

      return null;
    } catch (e) {
      // 이미지 로드 실패는 치명적이지 않음
      return null;
    }
  }

  /// ===================================================================
  /// 4. 디바이스 상세 정보 조회 (RTSP 스트림 정보 포함)
  /// ✅ 새로 추가: GET /api/v1/devices/{deviceId}
  /// ===================================================================
  Future<DeviceDetailModel> fetchDeviceDetail(int deviceId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception('로그인 정보가 없습니다.');

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/devices/$deviceId');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return DeviceDetailModel.fromJson(response.data);
      }

      throw Exception('Device 데이터 형식 오류');
    } on DioException catch (e) {
      throw _handleError(e, 'Device 상세 조회 실패');
    }
  }

  /// ===================================================================
  /// 에러 처리 헬퍼
  /// ===================================================================
  Exception _handleError(DioException e, String context) {
    if (e.response != null) {
      return Exception('$context: ${e.response?.statusCode} - ${e.response?.data}');
    }
    return Exception('$context: ${e.message}');
  }
}