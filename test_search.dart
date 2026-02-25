import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://huggingface.co/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  try {
    final query = 'gemma 3 1b';
    final response = await _dio.get('/models', queryParameters: {
      'search': query.isEmpty ? 'gguf' : '$query gguf',
      'filter': 'gguf',
      'sort': 'downloads',
      'direction': '-1',
      'limit': 20,
    });

    if (response.data is List) {
      final results = response.data as List;
      print("Found ${results.length} results.");
      for (var json in results) {
        print("- ${json['id']}");
      }
    } else {
      print("Not a list.");
    }
  } catch (e) {
    print("Error: $e");
  }
}
