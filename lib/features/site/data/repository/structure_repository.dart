import 'package:dio/dio.dart';
import '../model/structure_response_model.dart';
import '../model/structure_summary_model.dart'; // 방금 만든 모델 import

class StructureRepository {
  final Dio _dio;

  StructureRepository({Dio? dio}) : _dio = dio ?? Dio();

  // -------------------------------------------------------------
  // 1. Structure(Dashboard) 목록 조회
  // GET /api/v1/dashboards
  // -------------------------------------------------------------
  Future<List<StructureSummaryModel>> fetchStructureList() async {
    const String path = '/api/v1/dashboards';

    try {
      // 필요 시 토큰 헤더 추가
      final response = await _dio.get(
        path,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => StructureSummaryModel.fromJson(json)).toList();
      } else {
        throw Exception('목록 로드 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('서버 통신 오류: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류: $e');
    }
  }

  // -------------------------------------------------------------
  // 2. Structure 상세 정보 조회 (ID로 조회)
  // GET /api/v1/dashboards/{id}
  // -------------------------------------------------------------
  Future<StructureResponseModel> fetchStructureDetail(int structureId) async {
    final String path = '/api/v1/dashboards/$structureId';

    try {
      final response = await _dio.get(
        path,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return StructureResponseModel.fromJson(response.data);
      } else {
        throw Exception('상세 정보 로드 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('서버 통신 오류: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류: $e');
    }
  }
}