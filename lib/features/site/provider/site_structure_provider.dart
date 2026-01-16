import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/model/site_group_model.dart';
import '../data/model/site_structure_model.dart';

// Repository Provider
final siteRepositoryProvider = Provider((ref) => SiteRepository());

class SiteRepository {
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://220.76.77.250:5003/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 현장 목록 조회 (Dropdown용)
  Future<List<SiteGroupModel>> fetchSiteGroups() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception("로그인 정보가 없습니다.");
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('/sitegroups');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => SiteGroupModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching site groups: $e");
      return []; // 에러 시 빈 리스트 반환 (혹은 rethrow)
    }
  }

  Future<SiteStructureModel> fetchSiteStructure(int siteGroupId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) throw Exception("로그인 정보가 없습니다.");

      _dio.options.headers['Authorization'] = 'Bearer $token';

      // 병렬 호출
      final results = await Future.wait([
        _dio.get('/sitegroups/$siteGroupId'),
        _dio.get('/sitegroups/$siteGroupId/position/entrants'),
        _dio.get('/sitegroups/$siteGroupId/position/equipments'),
      ]);

      final siteResponse = results[0];
      final workerResponse = results[1];
      final equipmentResponse = results[2];

      // ------------------------------------------------------------------
      // [디버깅 로그] 실제 데이터가 들어오는지 확인
      // ------------------------------------------------------------------
      debugPrint('🔍 [API 로그] Site Data: ${siteResponse.data}');
      debugPrint('🔍 [API 로그] Worker Raw Data: ${workerResponse.data}');
      debugPrint('🔍 [API 로그] Equipment Raw Data: ${equipmentResponse.data}');


      // 1. 현장 이름
      String siteName = "Unknown Site";
      if (siteResponse.statusCode == 200) {
        // null 체크 및 타입 확인
        final data = siteResponse.data;
        if (data is Map<String, dynamic>) {
          siteName = data['name'] ?? "Unknown Site";
        }
      }

      // 2. 장비 데이터 파싱 (List 또는 Map['data'] 모두 대응)
      List<EquipmentModel> equipments = [];
      if (equipmentResponse.statusCode == 200) {
        final rawData = equipmentResponse.data;
        List<dynamic> list = [];

        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map<String, dynamic> && rawData['data'] is List) {
          list = rawData['data'];
        }

        debugPrint('🔍 [API 로그] 파싱된 장비 개수: ${list.length}');

        equipments = list.map((e) => EquipmentModel.fromJson(e)).toList();
      }

      // 3. 작업자 데이터 파싱
      List<WorkerDetailModel> allWorkers = [];
      if (workerResponse.statusCode == 200) {
        final rawData = workerResponse.data;
        List<dynamic> list = [];

        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map<String, dynamic> && rawData['data'] is List) {
          list = rawData['data'];
        }

        debugPrint('🔍 [API 로그] 파싱된 작업자 개수: ${list.length}');

        allWorkers = list.map((e) => WorkerDetailModel.fromJson(e)).toList();
      }

      // 작업자 그룹핑 로직 (Reader Serial 기준)
      Map<String, List<WorkerDetailModel>> groupedWorkers = {};
      for (var worker in allWorkers) {
        String key = worker.readerSerial.isNotEmpty ? worker.readerSerial : "Unknown Zone";
        if (!groupedWorkers.containsKey(key)) {
          groupedWorkers[key] = [];
        }
        groupedWorkers[key]!.add(worker);
      }

      List<WorkerGroupModel> workerGroups = [];
      int index = 0;
      groupedWorkers.forEach((key, workers) {
        // [위치 분산] 아이콘이 겹치지 않게 X 좌표를 조금씩 띄움
        workerGroups.add(WorkerGroupModel(
          zoneName: key,
          x: 400.0 + (index * 250), // 400부터 시작해서 250씩 오른쪽으로
          y: 600.0,                 // Y는 600으로 고정 (도면 중앙 하단 쯤)
          workers: workers,
        ));
        index++;
      });

      return SiteStructureModel(
        siteName: siteName,
        mapImageUrl: "",
        width: 2000,
        height: 1000,
        equipments: equipments,
        workerGroups: workerGroups,
      );

    } on DioException catch (e) {
      debugPrint("API Error: ${e.message}");
      if (e.response != null) {
        debugPrint("Response Data: ${e.response?.data}");
      }
      rethrow;
    }
  }
}

final siteStructureProvider = FutureProvider.family<SiteStructureModel, int>((ref, siteId) async {
  final repository = ref.watch(siteRepositoryProvider);
  return repository.fetchSiteStructure(siteId);
});

// 사이트 목록 Provider
final siteListProvider = FutureProvider<List<SiteGroupModel>>((ref) async {
  final repository = ref.watch(siteRepositoryProvider);
  return repository.fetchSiteGroups();
});