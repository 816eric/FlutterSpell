import 'dart:convert';
import 'package:http/http.dart' as http;

class SpellApiService {

  final String baseUrl = "http://192.168.18.88:8000/";

  // Static method to get user profile
  static Future<Map<String, dynamic>> getUserProfile(String userName) async {
    final service = SpellApiService();
    final response = await http.get(Uri.parse('${service.baseUrl}users/$userName'));
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