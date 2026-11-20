// lib/features/informasi_ta/data/informasi_ta_service.dart

import '../../../../core/api_client.dart';
import '../../../../model/informasi_ta_model.dart';

class InformasiTAService {
  final ApiClient _client = ApiClient.instance;

  Future<List<InformasiTAModel>> getInformasiTA({
    int page = 1,
    int perPage = 15,
    String? kategori,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
      queryParams['kategori'] = kategori;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final queryStr = Uri(queryParameters: queryParams).query;
    final path = '/mahasiswa/informasi-ta?$queryStr';

    final response = await _client.get(path);
    final data = response['data'];

    final List<dynamic> items = (data is Map && data['data'] is List)
        ? data['data'] as List<dynamic>
        : (data is List ? data : <dynamic>[]);

    return items
        .map((item) =>
            InformasiTAModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<InformasiTAModel> getDetail(int id) async {
    final response = await _client.get('/mahasiswa/informasi-ta/$id');
    return InformasiTAModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map));
  }
}
