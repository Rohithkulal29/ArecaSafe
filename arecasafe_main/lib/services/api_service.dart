// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';                 // FIXED
import '../services/auth_services.dart';    // FIXED

class ApiService {
  static Map<String, String> _headers() => {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": "Bearer $SUPABASE_ANON_KEY",
        "Content-Type": "application/json",
      };

  static Future<List<dynamic>> fetchLiveSensor() async {
    final user = AuthServices.currentUser();
    if (user == null) return [];

    final url =
        "$SUPABASE_URL/rest/v1/sensor_data?select=*&user_id=eq.${user.id}&order=created_at.desc&limit=1";

    final res = await http.get(Uri.parse(url), headers: _headers());
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> fetchHistory() async {
    final user = AuthServices.currentUser();
    if (user == null) return [];

    final url =
        "$SUPABASE_URL/rest/v1/fruit_rot_history?select=*&user_id=eq.${user.id}&order=predicted_at.desc";

    final res = await http.get(Uri.parse(url), headers: _headers());
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> uploadImage(String path) async {
    final uri = Uri.parse("$BACKEND_BASE/predict/image");

    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return json.decode(body) as Map<String, dynamic>;
    }
    return null;
  }
}
