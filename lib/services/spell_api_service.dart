import 'dart:convert';
import 'package:http/http.dart' as http;

class SpellApiService {
  // --- All static methods must be inside this class body ---
  
  //static final String baseUrl = "https://spellbackend.onrender.com/";
  //static final String baseUrl = "http://127.0.0.1:8000/";
  static final String baseUrl = "https://spellbackend.fly.dev/";

  //create the static methond below this line

  // Static method to delete a tag by tagId (admin/global)
  static Future<void> deleteTag(int tagId) async {
    final response = await http.delete(
      Uri.parse('${SpellApiService.baseUrl}tags/admin/delete/$tagId'),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to delete tag');
    }
  }

  // Static method to assign a tag to multiple words for a user
  static Future<void> assignTagToWords(String userName, List<int> wordIds, int tagId) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}tags/user/$userName/assign-to-words'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tag_id': tagId, 'word_ids': wordIds}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to assign tag to words');
    }
  }

  // Static method to create a user word
  static Future<void> createUserWord(String userName, Map<String, dynamic> wordData, {String? tag}) async {
    final uri = Uri.parse('${SpellApiService.baseUrl}words/users/$userName/words/')
      .replace(queryParameters: tag != null && tag.isNotEmpty ? {'tag': tag} : null);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(wordData),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create user word');
    }
  }

  // Get all tags (admin/global)
  static Future<List<Map<String, dynamic>>> getAllTags() async {
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}tags/all'));
    if (response.statusCode == 200) {
      final List<dynamic> tags = jsonDecode(response.body);
      return tags.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to get all tags');
    }
  }

  // Assign multiple tags to user
  static Future<void> assignTagsToUser(String userName, List<int> tagIds) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}tags/user/$userName/assign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tagIds),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to assign tags');
    }
  }

  // Unassign multiple tags from user
  static Future<void> unassignTagsFromUser(String userName, List<int> tagIds) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}tags/user/$userName/unassign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tagIds),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to unassign tags');
    }
  }

  // Delete a user-owned tag
  static Future<void> deleteUserTag(String userName, int tagId) async {
    final response = await http.delete(
      Uri.parse('${SpellApiService.baseUrl}tags/user/$userName/delete/$tagId'),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to delete tag');
    }
  }

  // Static method to get latest login tag for a user
  static Future<String?> getLatestLoginTag(String userName) async {
    final service = SpellApiService();
    final uri = Uri.parse('${SpellApiService.baseUrl}login-history/user/$userName');
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
    final uri = Uri.parse('${SpellApiService.baseUrl}login-history/');
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
      Uri.parse('${SpellApiService.baseUrl}users/'),
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
      Uri.parse('${SpellApiService.baseUrl}users/$userName/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile');
    }
  }

  // Static method to get user profile
  static Future<Map<String, dynamic>> getUserProfile(String userName) async {
    final service = SpellApiService();
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/profile'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile');
    }
  }

  // Static method to get user tags
  static Future<List<Map<String, dynamic>>> getUserTags(String userName) async {
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}tags/user/$userName'));
    print('DEBUG getUserTags response.body: ' + response.body);
    if (response.statusCode == 200) {
      final List<dynamic> tags = jsonDecode(response.body);
      print('DEBUG getUserTags decoded tags: ' + tags.toString());
      // Ensure all tags have 'tag' as the tag name field, not 'name'
      return tags.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to get user tags');
    }
  }

  // Static method to get words (single tag)
  static Future<List<Map<String, dynamic>>> getWords(String userName, String tag) async {
    final url = '${SpellApiService.baseUrl}words/users/$userName/words/?tags=$tag';
    //print('DEBUG getWords URL: $url');
    final response = await http.get(Uri.parse(url));
    print('DEBUG getWords response.body: ${response.body}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      //print('DEBUG getWords decoded: $decoded');
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      //print('DEBUG getWords failed with status: ${response.statusCode}');
      throw Exception('Failed to fetch words');
    }
  }
 

  // (fetchWords instance method removed, now handled by static getWords)

  Future<void> logStudy(String userName, int wordId) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}users/$userName/study/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'word_id': wordId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to log study');
    }
  }

  Future<Map<String, dynamic>> getPoints(String userName) async {
    final service = SpellApiService();
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/points/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get points');
    }
  }
  
  static Future<void> createUserTag(String userName, Map tag) async {
    final service = SpellApiService();
  }

  static Future<Map<String, dynamic>> getDeck(String userName, int limit) async {
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/deck?limit=$limit'));
    if (response.statusCode != 200) {
      throw Exception('Deck fetch failed: {response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> submitReview(String userName, int wordId, int quality) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}users/$userName/review'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'word_id': wordId, 'quality': quality}),
    );
    if (response.statusCode != 200) {
      throw Exception('Review submit failed: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

}