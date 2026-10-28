import 'token_storage.dart';

Future<Map<String, String>> authHeaders() async {
  final token = await TokenStorage.read();
  return {
    'Accept': 'application/json',
    'content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
