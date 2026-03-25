import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/position_models.dart';

/// ========================================================================
/// 실시간 Position API Repository (Layout과 분리)
/// ========================================================================
class PositionRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  PositionRepository({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
    baseUrl: 'https://220.76.77.250:5003/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )),
        _storage = storage ?? const FlutterSecureStorage();

  /// ===================================================================
  /// 1. 작업자 위치 조회 (humanCount 업데이트용)
  /// GET /api/v1/sitegroups/{id}/position/entrants
  /// ===================================================================
  Future<List<WorkerPositionModel>> fetchWorkerPositions(int siteGroupId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception('로그인 정보가 없습니다.');

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/sitegroups/$siteGroupId/position/entrants');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] as List? ?? []);

        return data.map((json) => WorkerPositionModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      // 위치 데이터 실패는 빈 리스트 반환 (비치명적)
      print('작업자 위치 조회 실패: ${e.message}');
      return [];
    }
  }

  /// ===================================================================
  /// 2. 장비 위치 조회
  /// GET /api/v1/sitegroups/{id}/position/equipments
  /// ===================================================================
  Future<List<EquipmentPositionModel>> fetchEquipmentPositions(int siteGroupId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception('로그인 정보가 없습니다.');

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/sitegroups/$siteGroupId/position/equipments');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] as List? ?? []);

        return data.map((json) => EquipmentPositionModel.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('장비 위치 조회 실패: ${e.message}');
      return [];
    }
  }

  /// ===================================================================
  /// 3. 집계 데이터 생성 (Provider에서 사용)
  /// ===================================================================
  Future<PositionAggregation> fetchPositionAggregation(int siteGroupId) async {
    final workers = await fetchWorkerPositions(siteGroupId);
    return PositionAggregation.fromWorkerList(workers);
  }
}