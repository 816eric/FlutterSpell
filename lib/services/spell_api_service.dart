import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

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
    // removed unused variable
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
    // removed unused variable
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
    // removed unused variable
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
    // removed unused variable
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
    // removed unused variable
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/profile'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile');
    }
  }

  // Verify user password with backend (matches FastAPI route)
  static Future<bool> verifyUserPassword(String userName, String password) async {
    //print('DEBUG verifyUserPassword: userName=$userName, password=$password');
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}users/$userName/verify-password'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'password=${Uri.encodeComponent(password)}',
    );
    //print('DEBUG verifyUserPassword response.statusCode: ${response.statusCode}');
    //print('DEBUG verifyUserPassword response.body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      //print('DEBUG verifyUserPassword decoded data: $data');
      return data['verified'] == true;
    } else {
      return false;
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

  // Future<Map<String, dynamic>> getPoints(String userName) async {
  //     // removed unused variable
  //     final response = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/points/'));
  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     } else {
  //       throw Exception('Failed to get points');
  //     }
  //   }
  
  static Future<void> createUserTag(String userName, Map tag) async {
    // removed unused variable
  }
  static Future<Map<String, dynamic>> getDeck(String userName, int limit, {String? tag}) async {
    final qp = <String, String>{'limit': '$limit'};
    if (tag != null && tag.isNotEmpty) qp['tag'] = tag;
    final uri = Uri.parse('${SpellApiService.baseUrl}users/$userName/deck').replace(queryParameters: qp);
    print('DEBUG getDeck uri: $uri');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Deck fetch failed: ${response.statusCode}');
    }
    print('DEBUG getDeck response.body: ${response.body}');
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

  // Call Gemini AI backend to extract words from image
  static Future<List<String>> extractWordsFromImageWeb(XFile pickedFile) async {
    final uri = Uri.parse('${SpellApiService.baseUrl}ai/extract-words');
    var request = http.MultipartRequest('POST', uri);
    // Guess content type from file extension
    String? contentType;
    final lowerName = pickedFile.name.toLowerCase();
    if (lowerName.endsWith('.png')) {
      contentType = 'image/png';
    } else if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (lowerName.endsWith('.gif')) {
      contentType = 'image/gif';
    } else {
      contentType = 'image/png'; // fallback
    }
    request.files.add(await http.MultipartFile.fromBytes(
      'file',
      await pickedFile.readAsBytes(),
      filename: pickedFile.name,
      contentType: MediaType.parse(contentType),
    ));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final List<dynamic> words = jsonDecode(response.body);
      print('DEBUG extractWordsFromImageWeb response.body: ${response.body}');
      return words.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to extract words: ${response.body}');
    }
  }

  // ===== Leaderboard =====

  static Future<Map<String, dynamic>> getLeaderboardTop({
    int limit = 20,
    String? school,
    String? grade,
    String? userNameHeader, // optional; used for auto-apply defaults on server
    }) async {
    final qp = <String, String>{ 'limit': '$limit' };
    if (school != null) qp['school'] = school;
    if (grade != null) qp['grade'] = grade;

    final uri = Uri.parse('${SpellApiService.baseUrl}leaderboard/top').replace(queryParameters: qp);
    final headers = <String, String>{};
    if (userNameHeader != null) headers['X-User-Name'] = userNameHeader;

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Leaderboard fetch failed: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
    }

    static Future<Map<String, dynamic>> getLeaderboardMe({
    int limit = 20,
    String? school,
    String? grade,
    String? userNameHeader,
    }) async {
    final qp = <String, String>{ 'limit': '$limit' };
    if (school != null) qp['school'] = school;
    if (grade != null) qp['grade'] = grade;

    final uri = Uri.parse('${SpellApiService.baseUrl}leaderboard/me').replace(queryParameters: qp);
    final headers = <String, String>{};
    if (userNameHeader != null) headers['X-User-Name'] = userNameHeader;

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Leaderboard(me) fetch failed: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
    }

  // Fetch all unique schools for dropdown
  static Future<List<String>> getLeaderboardSchools() async {
    final uri = Uri.parse('${SpellApiService.baseUrl}leaderboard/schools');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schools: ${resp.statusCode}');
    }
    final List<dynamic> schools = json.decode(resp.body);
    return schools.map((e) => e.toString()).toList();
  }

  // Fetch all unique grades for dropdown, with optional school filter
  static Future<List<String>> getLeaderboardGrades({String? school}) async {
    final qp = <String, String>{};
    if (school != null && school.isNotEmpty) qp['school'] = school;
    final uri = Uri.parse('${SpellApiService.baseUrl}leaderboard/grades').replace(queryParameters: qp);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch grades: ${resp.statusCode}');
    }
    final List<dynamic> grades = json.decode(resp.body);
    return grades.map((e) => e.toString()).toList();
  }

  // ===== Rewards =====
    static Future<Map<String, dynamic>> getPoints(String userName) async {
      final resp = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/points/'));
      if (resp.statusCode != 200) {
        throw Exception('Get points failed: ${resp.statusCode}');
      }
      return json.decode(resp.body) as Map<String, dynamic>;
    }

  static Future<Map<String, dynamic>> addPoints(String userName, int points, String reason) async {
    final body = json.encode({'points': points, 'reason': reason});
    final resp = await http.post(
      Uri.parse('${SpellApiService.baseUrl}users/$userName/points/add'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception('Add points failed: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> redeemPoints(String userName, String item, int points) async {
    final body = json.encode({'item': item, 'points': points});
    final resp = await http.post(
      Uri.parse('${SpellApiService.baseUrl}users/$userName/points/redeem'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (resp.statusCode == 400 && resp.body.contains('insufficient_points')) {
      throw Exception('insufficient_points');
    }
    if (resp.statusCode != 200) {
      throw Exception('Redeem failed: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRewardHistory(String userName, {int page = 1}) async {
  final resp = await http.get(Uri.parse('${SpellApiService.baseUrl}users/$userName/points/history?page=$page'));
    if (resp.statusCode != 200) {
      throw Exception('History failed: ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  // Get login history for a user
  static Future<List<dynamic>> getLoginHistory(String userName) async {
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}login-history/user/$userName'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get login history');
    }
  }

  // Get user settings
  static Future<Map<String, dynamic>?> getUserSettings(int userId) async {
    final response = await http.get(Uri.parse('${SpellApiService.baseUrl}settings/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get user settings');
    }
  }

  // Update user settings
    static Future<Map<String, dynamic>> updateUserSettings(
      int userId, {
      String? studyWordsSource,
      int? numStudyWords,
      int? spellRepeatCount,
    }) async {
      final uri = Uri.parse('${SpellApiService.baseUrl}settings/$userId');
      final params = <String, String>{};
      if (studyWordsSource != null) params['study_words_source'] = studyWordsSource;
      if (numStudyWords != null) params['num_study_words'] = numStudyWords.toString();
      if (spellRepeatCount != null) params['spell_repeat_count'] = spellRepeatCount.toString();
      final response = await http.post(uri.replace(queryParameters: params));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update user settings');
      }
    }

  // ===== Back Card =====

  // Update back card for a word
  static Future<void> updateBackCard(int wordId, String backCard) async {
    final response = await http.put(
      Uri.parse('${SpellApiService.baseUrl}words/$wordId/back-card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'back_card': backCard}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update back card');
    }
  }

  // Get back card for a word
  static Future<String?> getBackCard(int wordId) async {
    final response = await http.get(
      Uri.parse('${SpellApiService.baseUrl}words/$wordId/back-card'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['back_card'] as String?;
    } else {
      throw Exception('Failed to get back card');
    }
  }

  // ===== Quiz =====

  // Update quiz for a word
  static Future<void> updateQuiz(int wordId, Map<String, dynamic> quiz) async {
    final response = await http.put(
      Uri.parse('${SpellApiService.baseUrl}words/$wordId/quiz'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'quiz': jsonEncode(quiz)}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update quiz');
    }
  }

  // Get quiz for a word
  static Future<Map<String, dynamic>?> getQuiz(int wordId) async {
    final response = await http.get(
      Uri.parse('${SpellApiService.baseUrl}words/$wordId/quiz'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final quizStr = data['quiz'] as String?;
      if (quizStr == null || quizStr.isEmpty || quizStr.toLowerCase() == 'none') {
        return null;
      }
      return jsonDecode(quizStr) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get quiz');
    }
  }

  // ===== History Tracking =====

  // Save study session (batch of records)
  static Future<Map<String, dynamic>> saveStudySession(String userName, List<Map<String, dynamic>> records) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}history/study-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_name': userName,
        'records': records,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to save study session');
    }
  }

  // Save quiz session (batch of records)
  static Future<Map<String, dynamic>> saveQuizSession(String userName, List<Map<String, dynamic>> records) async {
    final response = await http.post(
      Uri.parse('${SpellApiService.baseUrl}history/quiz-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_name': userName,
        'records': records,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to save quiz session');
    }
  }

  // Get study history for a user
  static Future<List<dynamic>> getStudyHistory(String userName, {int limit = 100}) async {
    final response = await http.get(
      Uri.parse('${SpellApiService.baseUrl}history/study/$userName?limit=$limit'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get study history');
    }
  }

  // Get quiz history for a user
  static Future<List<dynamic>> getQuizHistory(String userName, {int limit = 100}) async {
    final response = await http.get(
      Uri.parse('${SpellApiService.baseUrl}history/quiz/$userName?limit=$limit'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to get quiz history');
    }
  }

  // Clear all study history for a user
  static Future<Map<String, dynamic>> clearStudyHistory(String userName) async {
    final response = await http.delete(
      Uri.parse('${SpellApiService.baseUrl}history/study/$userName'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to clear study history');
    }
  }

  // Clear all quiz history for a user
  static Future<Map<String, dynamic>> clearQuizHistory(String userName) async {
    final response = await http.delete(
      Uri.parse('${SpellApiService.baseUrl}history/quiz/$userName'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to clear quiz history');
    }
  }



}