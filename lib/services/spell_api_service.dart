import 'dart:convert';
import 'package:http/http.dart' as http;

class SpellApiService {
  // Static method to get latest login tag for a user
  static Future<String?> getLatestLoginTag(String userName) async {
    final service = SpellApiService();
    final uri = Uri.parse('${service.baseUrl}login-history/user/$userName');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> history = jsonDecode(response.body);
      if (history.isNotEmpty) {
        // Find the latest entry with a tag
        for (final entry in history.reversed) {
          if (entry['tag'] != null && entry['tag'].toString().isNotEmpty) {
            return entry['tag'];
          }
        }
      }
      return null;
    } else {
      throw Exception('Failed to get login history');
    }
  }
  // Static method to log login/tag event
  static Future<void> logLoginHistory(String userName, {String? tag}) async {
    final service = SpellApiService();
    final uri = Uri.parse('${service.baseUrl}login-history/');
    final params = <String, String>{'user_name': userName};
    if (tag != null) params['tag'] = tag;
    final response = await http.post(uri.replace(queryParameters: params));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to log login history');
    }
  }
  // Static method to create user profile
  static Future<void> createUserProfile(Map<String, dynamic> data) async {
    final service = SpellApiService();
    final response = await http.post(
      Uri.parse('${service.baseUrl}users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create user profile');
    }
  }
  // Static method to update user profile
  static Future<void> updateUserProfile(String userName, Map<String, dynamic> data) async {
    final service = SpellApiService();
    final response = await http.put(
      Uri.parse('${service.baseUrl}users/$userName/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile');
    }
  }

  final String baseUrl = "http://192.168.18.88:8000/";

  // Static method to get user profile
  static Future<Map<String, dynamic>> getUserProfile(String userName) async {
    final service = SpellApiService();
    final response = await http.get(Uri.parse('${service.baseUrl}users/$userName/profile'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile');
    }
  }

  // Static method to get user tags
  static Future<List<String>> getUserTags(String userName) async {
    final service = SpellApiService();
    final response = await http.get(Uri.parse('${service.baseUrl}words/users/$userName/tags/'));
    if (response.statusCode == 200) {
      final List<dynamic> tags = jsonDecode(response.body);
      return tags.cast<String>();
    } else {
      throw Exception('Failed to get user tags');
    }
  }

  // Static method to get words
  static Future<List<Map<String, dynamic>>> getWords(String userName, List<String> tags) async {
    final service = SpellApiService();
    return await service.fetchWords(userName, tags);
  }
 

  Future<List<Map<String, dynamic>>> fetchWords(String userName, List<String> tags) async {
    final service = SpellApiService();
    final tagQuery = tags.join(',');
    final response = await http.get(Uri.parse('${service.baseUrl}words/users/$userName/words/?tags=$tagQuery'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch words');
    }
  }

  Future<void> logStudy(String userName, int wordId) async {
    final service = SpellApiService();
    final response = await http.post(
      Uri.parse('${service.baseUrl}users/$userName/study/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'word_id': wordId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to log study');
    }
  }

  Future<Map<String, dynamic>> getPoints(String userName) async {
    final service = SpellApiService();
    final response = await http.get(Uri.parse('${service.baseUrl}users/$userName/points/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get points');
    }
  }
}