import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

/// AI Service for Spell Application
/// Supports multiple AI providers: Gemini, OpenAI, DeepSeek, Qianwen
class AIService {
  // Singleton pattern
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // AI Provider Configuration Keys
  static const String _keyAiProvider = 'ai_provider';
  static const String _keyAiModel = 'ai_model';
  static const String _keyAiApiKey = 'ai_api_key';
  
  // Default values
  static const String _defaultProvider = 'gemini';
  static const String _defaultModel = 'gemini-2.5-flash-lite';

  // Cached settings
  String? _cachedProvider;
  String? _cachedModel;
  String? _cachedApiKey;

  /// Get AI Provider
  Future<String> getAiProvider() async {
    if (_cachedProvider != null) return _cachedProvider!;
    final prefs = await SharedPreferences.getInstance();
    _cachedProvider = prefs.getString(_keyAiProvider) ?? _defaultProvider;
    return _cachedProvider!;
  }

  /// Get AI Model
  Future<String> getAiModel() async {
    if (_cachedModel != null) return _cachedModel!;
    final prefs = await SharedPreferences.getInstance();
    _cachedModel = prefs.getString(_keyAiModel) ?? _defaultModel;
    return _cachedModel!;
  }

  /// Get AI API Key
  Future<String> getAiApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;
    final prefs = await SharedPreferences.getInstance();
    _cachedApiKey = prefs.getString(_keyAiApiKey) ?? '';
    return _cachedApiKey!;
  }

  /// Set AI Provider
  Future<void> setAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiProvider, provider);
    _cachedProvider = provider;
  }

  /// Set AI Model
  Future<void> setAiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiModel, model);
    _cachedModel = model;
  }

  /// Set AI API Key
  Future<void> setAiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiApiKey, apiKey);
    _cachedApiKey = apiKey;
  }

  // Custom prompt keys
  static const String _keyPromptEnglish = 'ai_prompt_english';
  static const String _keyPromptChinese = 'ai_prompt_chinese';

  /// Get English prompt (returns custom or default)
  Future<String> getEnglishPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_keyPromptEnglish) ?? '';
    if (custom.trim().isNotEmpty) return custom;
    // Default English prompt (no pinyin for English words)
    return 'Create concise study content for the word "\$WORD" as exactly four lines:\n'
        '1) How to memorize: tips to help remember how to spell the word.\n'
        '2) Explanation: 2-3 sentences.\n'
        '3) Similar words: 2-3 similar/related words on one line, comma-separated.\n'
        '4) Example: one sample sentence using the word.\n'
        'Return plain text only: no Markdown, no bullets or symbols (#, *, -, •, ```). Use only these four titles — "How to memorize:", "Explanation:", "Similar words:", and "Example:" — and no other labels or headings. Keep under 1000 words.';
  }

  /// Get Chinese prompt (returns custom or default)
  Future<String> getChinesePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_keyPromptChinese) ?? '';
    if (custom.trim().isNotEmpty) return custom;
    // Default Chinese prompt
    return '请为单词"\$WORD"生成简洁的学习内容，并严格按以下五行输出：\n'
        '1) 拼音：给出该词的拼音（汉语罗马字）。\n'
        '2) 如何记忆：提供记忆技巧。\n'
        '3) 解释：2-3句简短中文释义, 和简短的英文解释。\n'
        '4) 相似字：给出2-3个相似或相关字，使用中文或英文，逗号分隔在同一行。\n'
        '5) 例句：给出一个包含该词的例句。\n'
        '输出要求：仅限纯文本，不使用任何Markdown或符号（如#、*、-、•、```等）；允许且只允许以下五个固定标题："拼音：""如何记忆：""解释：""相似词：""例句："。不要使用其他任何标签或标题。整体不超过1000字。';
  }

  /// Set English prompt
  Future<void> setEnglishPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPromptEnglish, prompt);
  }

  /// Set Chinese prompt
  Future<void> setChinesePrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPromptChinese, prompt);
  }

  /// Clear cache (call when settings change)
  void clearCache() {
    _cachedProvider = null;
    _cachedModel = null;
    _cachedApiKey = null;
  }

  /// Get default model for a provider
  static String getDefaultModelForProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return 'gemini-2.5-flash-lite';
      case 'openai':
        return 'gpt-4o-mini';
      case 'deepseek':
        return 'deepseek-chat';
      case 'qianwen':
        return 'qwen-turbo';
      default:
        return 'gemini-2.5-flash-lite';
    }
  }

  /// Get available models for a provider
  static List<String> getModelsForProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return [
          'gemini-3.0-pro',
          'gemini-2.5-pro',
          'gemini-2.5-flash',
          'gemini-2.5-flash-lite',
          'gemini-2.0-flash',
          'gemini-2.0-flash-lite',
        ];
      case 'openai':
        return [
          'gpt-4o-mini',
          'gpt-4o',
          'gpt-4-turbo',
          'gpt-3.5-turbo',
        ];
      case 'deepseek':
        return [
          'deepseek-chat',
          'deepseek-coder',
          'deepseek-reasoner',
        ];
      case 'qianwen':
        return [
          'qwen-turbo',
          'qwen-plus',
          'qwen-max',
          'qwen-coder-turbo',
        ];
      default:
        return ['gemini-2.0-flash-exp'];
    }
  }

  /// Get provider display name
  static String getProviderDisplayName(String provider) {
    switch (provider) {
      case 'gemini':
        return 'Google Gemini';
      case 'openai':
        return 'OpenAI';
      case 'deepseek':
        return 'DeepSeek';
      case 'qianwen':
        return 'Qianwen (Alibaba)';
      default:
        return provider;
    }
  }

  /// Get API key hint for a provider
  static String getApiKeyHint(String provider) {
    switch (provider) {
      case 'gemini':
        return 'Get from Google AI Studio (ai.google.dev)';
      case 'openai':
        return 'Get from OpenAI Platform (platform.openai.com)';
      case 'deepseek':
        return 'Get from DeepSeek Platform (platform.deepseek.com)';
      case 'qianwen':
        return 'Get from Alibaba Cloud Console';
      default:
        return 'Enter your API key';
    }
  }

  /// Compress image if it's too large
  static Uint8List _compressImage(Uint8List imageBytes, {int maxSizeKB = 512}) {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('[AIService] Failed to decode image, using original');
        return imageBytes;
      }
      
      print('[AIService] Original image: ${image.width}x${image.height}');
      
      // Calculate compression ratio based on current size
      final currentSizeKB = imageBytes.length / 1024;
      print('[AIService] Current size: ${currentSizeKB.toStringAsFixed(0)} KB');
      
      if (currentSizeKB <= maxSizeKB) {
        print('[AIService] Image already small enough');
        return imageBytes;
      }
      
      // Calculate target dimensions to achieve target size
      final compressionRatio = maxSizeKB / currentSizeKB;
      final scaleFactor = (compressionRatio * 0.8).clamp(0.1, 1.0); // 0.8 for safety margin
      
      final newWidth = (image.width * scaleFactor).round();
      final newHeight = (image.height * scaleFactor).round();
      
      print('[AIService] Compressing to: ${newWidth}x${newHeight} (scale: ${(scaleFactor * 100).toStringAsFixed(1)}%)');
      
      // Resize the image
      final resized = img.copyResize(image, width: newWidth, height: newHeight);
      
      // Encode as JPEG with quality adjustment
      int quality = 85;
      Uint8List compressed;
      
      do {
        compressed = img.encodeJpg(resized, quality: quality);
        final compressedSizeKB = compressed.length / 1024;
        print('[AIService] Compressed size at quality $quality: ${compressedSizeKB.toStringAsFixed(0)} KB');
        
        if (compressedSizeKB <= maxSizeKB || quality <= 30) {
          break;
        }
        
        quality -= 10;
      } while (quality > 30);
      
      final finalSizeKB = compressed.length / 1024;
      print('[AIService] Final compressed size: ${finalSizeKB.toStringAsFixed(0)} KB');
      
      return compressed;
    } catch (e) {
      print('[AIService] Compression failed: $e, using original image');
      return imageBytes;
    }
  }

  /// Extract words from image using AI
  /// Returns a list of words extracted from the image
  Future<List<String>> extractWordsFromImage(dynamic imageSource) async {
    final provider = await getAiProvider();
    final model = await getAiModel();
    final apiKey = await getAiApiKey();

    if (apiKey.isEmpty) {
      throw Exception('API key is not configured. Please set it in Settings.');
    }

    // Read and encode the image - handle both File and XFile
    Uint8List imageBytes;
    String fileName;
    
    if (imageSource is XFile) {
      // Web or cross-platform XFile
      imageBytes = await imageSource.readAsBytes();
      fileName = imageSource.name.toLowerCase();
    } else if (imageSource is File) {
      // Mobile File
      if (!imageSource.existsSync()) {
        throw Exception('Image file does not exist');
      }
      imageBytes = imageSource.readAsBytesSync();
      fileName = imageSource.path.toLowerCase();
    } else {
      throw Exception('Unsupported image source type');
    }

    // Check and compress image if needed
    final originalSizeKB = imageBytes.length / 1024;
    print('[AIService] Original image size: ${originalSizeKB.toStringAsFixed(0)} KB');
    
    if (originalSizeKB > 512) { // 512KB
      print('[AIService] Image too large, compressing...');
      imageBytes = _compressImage(imageBytes, maxSizeKB: 512);
      
      final compressedSizeKB = imageBytes.length / 1024;
      print('[AIService] Compressed from ${originalSizeKB.toStringAsFixed(0)} KB to ${compressedSizeKB.toStringAsFixed(0)} KB');
    }

    // Call appropriate provider
    switch (provider) {
      case 'gemini':
        return await _extractWordsGemini(imageBytes, fileName, model, apiKey);
      case 'openai':
        return await _extractWordsOpenAI(imageBytes, fileName, model, apiKey);
      case 'deepseek':
        return await _extractWordsDeepSeek(imageBytes, fileName, model, apiKey);
      case 'qianwen':
        return await _extractWordsQianwen(imageBytes, fileName, model, apiKey);
      default:
        throw Exception('Unsupported AI provider: $provider');
    }
  }

  /// Extract words using Google Gemini
  Future<List<String>> _extractWordsGemini(
    Uint8List imageBytes,
    String fileName,
    String model,
    String apiKey,
  ) async {
    final base64Image = base64Encode(imageBytes);
    
    // Simple MIME type detection
    String mimeType = 'image/jpeg';
    if (fileName.endsWith('.png') && imageBytes.length <= 512 * 1024) {
      mimeType = 'image/png';
    } else if (fileName.endsWith('.gif') && imageBytes.length <= 512 * 1024) {
      mimeType = 'image/gif';
    } else if (fileName.endsWith('.webp') && imageBytes.length <= 512 * 1024) {
      mimeType = 'image/webp';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': 'Extract all spelling words or sentences from this image. '
                  'Return only the list of words or sentences, separated by commas. '
                  'If the image contains a worksheet or spelling list, extract only the spelling words.'
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 8192,
        'topP': 0.95,
        'topK': 40
      },
      'systemInstruction': {
        'parts': [
          {
            'text': 'You are a spelling word extractor. Respond ONLY with the words or sentences, comma-separated. Do not explain, do not think aloud, just provide the extracted text.'
          }
        ]
      }
    };

    Map<String, dynamic> responseData;
    
    if (kIsWeb) {
      // Use http package for web
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
      }
      
      responseData = jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // Use HttpClient for mobile
      final client = HttpClient();
      try {
        final request = await client.postUrl(url);
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode(requestBody));
        
        final response = await request.close();
        
        if (response.statusCode != 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          throw Exception('Gemini API Error ${response.statusCode}: $responseBody');
        }
        
        final responseBody = await response.transform(utf8.decoder).join();
        responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      } finally {
        client.close();
      }
    }

    // Parse response with detailed logging
    print('[AIService] Gemini response: ${jsonEncode(responseData)}');
    
    final candidates = responseData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini AI. Response: ${jsonEncode(responseData)}');
    }

    final candidate = candidates[0] as Map<String, dynamic>?;
    if (candidate == null) {
      throw Exception('Invalid candidate format');
    }
    
    final content = candidate['content'] as Map<String, dynamic>?;
    final finishReason = candidate['finishReason'];
    
    if (content == null) {
      throw Exception('No content in response. FinishReason: $finishReason');
    }
    
    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      // Handle MAX_TOKENS case - response was truncated
      if (finishReason == 'MAX_TOKENS') {
        throw Exception('Response truncated due to token limit. Try with a smaller or clearer image. FinishReason: $finishReason');
      }
      throw Exception('No parts in content. Content: ${jsonEncode(content)}, FinishReason: $finishReason');
    }

    final firstPart = parts[0] as Map<String, dynamic>?;
    if (firstPart == null || firstPart['text'] == null) {
      throw Exception('No text in first part. Parts: ${jsonEncode(parts)}');
    }
    
    final textResponse = firstPart['text'] as String;
    print('[AIService] Gemini text response: $textResponse');
    
    // Parse comma-separated words/sentences
    final words = textResponse
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    if (words.isEmpty) {
      // Fallback: try to extract any text
      final fallbackWords = textResponse
          .split(RegExp(r'[\n\r]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return fallbackWords.isNotEmpty ? fallbackWords : [textResponse.trim()];
    }
    
    print('[AIService] Extracted ${words.length} words: $words');
    return words;
  }

  /// Extract words using OpenAI
  Future<List<String>> _extractWordsOpenAI(
    Uint8List imageBytes,
    String fileName,
    String model,
    String apiKey,
  ) async {
    final base64Image = base64Encode(imageBytes);
    
    String mimeType = 'image/jpeg';
    if (fileName.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (fileName.endsWith('.gif')) {
      mimeType = 'image/gif';
    } else if (fileName.endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final requestBody = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Extract all spelling words or sentences from this image. Return only the list of words or sentences, separated by commas. If the image contains a worksheet or spelling list, extract only the spelling words.'
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image'
              }
            }
          ]
        }
      ],
      'max_tokens': 2048,
      'temperature': 0.1
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from OpenAI');
    }

    final message = choices[0]['message'];
    final content = message['content'] as String?;
    
    if (content == null || content.isEmpty) {
      throw Exception('No content in OpenAI response');
    }

    print('[AIService] OpenAI response content: $content');

    // Try to extract JSON array from response
    final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
    final match = jsonRegex.firstMatch(content);
    
    if (match != null) {
      try {
        final List<dynamic> words = jsonDecode(match.group(0)!);
        return words.map((e) => e.toString()).toList();
      } catch (e) {
        print('[AIService] Failed to parse JSON, trying comma-separated format: $e');
      }
    }
    
    // Fallback: try to parse as comma-separated text
    final words = content
        .split(',')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    
    if (words.isEmpty) {
      throw Exception('No words extracted from OpenAI response');
    }
    
    return words;
  }

  /// Extract words using DeepSeek
  Future<List<String>> _extractWordsDeepSeek(
    Uint8List imageBytes,
    String fileName,
    String model,
    String apiKey,
  ) async {
    final base64Image = base64Encode(imageBytes);
    
    String mimeType = 'image/jpeg';
    if (fileName.endsWith('.png')) {
      mimeType = 'image/png';
    }

    final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');

    final requestBody = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Extract all spelling words or sentences from this image. Return only the list of words or sentences, separated by commas. If the image contains a worksheet or spelling list, extract only the spelling words.'
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image'
              }
            }
          ]
        }
      ],
      'max_tokens': 2048,
      'temperature': 0.1
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from DeepSeek');
    }

    final message = choices[0]['message'];
    final content = message['content'] as String?;
    
    if (content == null || content.isEmpty) {
      throw Exception('No content in DeepSeek response');
    }

    print('[AIService] DeepSeek response content: $content');

    // Try to extract JSON array from response
    final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
    final match = jsonRegex.firstMatch(content);
    
    if (match != null) {
      try {
        final List<dynamic> words = jsonDecode(match.group(0)!);
        return words.map((e) => e.toString()).toList();
      } catch (e) {
        print('[AIService] Failed to parse JSON, trying comma-separated format: $e');
      }
    }
    
    // Fallback: try to parse as comma-separated text
    final words = content
        .split(',')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    
    if (words.isEmpty) {
      throw Exception('No words extracted from DeepSeek response');
    }
    
    return words;
  }

  /// Extract words using Qianwen (Alibaba)
  Future<List<String>> _extractWordsQianwen(
    Uint8List imageBytes,
    String fileName,
    String model,
    String apiKey,
  ) async {
    final base64Image = base64Encode(imageBytes);
    
    final url = Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation');

    final requestBody = {
      'model': model,
      'input': {
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'text': 'Extract all spelling words or sentences from this image. Return only the list of words or sentences, separated by commas. If the image contains a worksheet or spelling list, extract only the spelling words.'
              },
              {
                'image': 'data:image/jpeg;base64,$base64Image'
              }
            ]
          }
        ]
      },
      'parameters': {
        'max_tokens': 2048,
        'temperature': 0.1
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Qianwen API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final output = responseData['output'] as Map<String, dynamic>?;
    
    if (output == null) {
      throw Exception('No output from Qianwen');
    }

    final choices = output['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from Qianwen');
    }

    final message = choices[0]['message'];
    final content = message['content'] as String?;
    
    if (content == null || content.isEmpty) {
      throw Exception('No content in Qianwen response');
    }

    print('[AIService] Qianwen response content: $content');

    // Try to extract JSON array from response
    final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
    final match = jsonRegex.firstMatch(content);
    
    if (match != null) {
      try {
        final List<dynamic> words = jsonDecode(match.group(0)!);
        return words.map((e) => e.toString()).toList();
      } catch (e) {
        print('[AIService] Failed to parse JSON, trying comma-separated format: $e');
      }
    }
    
    // Fallback: try to parse as comma-separated text
    final words = content
        .split(',')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    
    if (words.isEmpty) {
      throw Exception('No words extracted from Qianwen response');
    }
    
    return words;
  }

  /// Generate back card content using AI
  /// Returns a string with explanation, similar words, and sample sentence
  Future<String> generateBackCard(String word, String language) async {
    final provider = await getAiProvider();
    final model = await getAiModel();
    final apiKey = await getAiApiKey();

    if (apiKey.isEmpty) {
      throw Exception('API key is not configured. Please set it in Settings.');
    }

    // Prepare prompt based on language, get custom or default prompts
    String promptTemplate;
    if (language == 'zh' || language == 'chinese') {
      promptTemplate = await getChinesePrompt();
    } else {
      promptTemplate = await getEnglishPrompt();
    }
    // Replace $WORD placeholder with actual word
    final prompt = promptTemplate.replaceAll('\$WORD', word);

    // Call appropriate provider
    // Debug info
    print('[AI BackCard] provider=$provider model=$model word="$word" language=$language');
    print('[AI BackCard] prompt:\n$prompt');

    String response;
    switch (provider) {
      case 'gemini':
        response = await _generateBackCardGemini(prompt, model, apiKey);
        break;
      case 'openai':
        response = await _generateBackCardOpenAI(prompt, model, apiKey);
        break;
      case 'deepseek':
        response = await _generateBackCardDeepSeek(prompt, model, apiKey);
        break;
      case 'qianwen':
        response = await _generateBackCardQianwen(prompt, model, apiKey);
        break;
      default:
        throw Exception('Unsupported AI provider: $provider');
    }
    
    return _sanitizeBackCard(response, word);
  }

  /// Generate quiz question using AI
  Future<Map<String, dynamic>> generateQuiz(String word, String language) async {
    final provider = await getAiProvider();
    final model = await getAiModel();
    final apiKey = await getAiApiKey();

    if (apiKey.isEmpty) {
      throw Exception('API key is not configured. Please set it in Settings.');
    }

    // Prepare quiz prompt
    final prompt = 'Generate a multiple choice quiz question for the word or phrase \'$word\' in this JSON format:\n'
        '{\n'
        '  "question": "Question text here",\n'
        '  "options": ["Option A", "Option B", "Option C", "Option D"],\n'
        '  "correct": 0\n'
        '}\n'
        'Where correct is the index (0-3) of the correct answer. Return ONLY valid JSON, no other text.';

    print('[AI Quiz] provider=$provider model=$model word="$word" language=$language');
    print('[AI Quiz] prompt:\n$prompt');

    String response;
    switch (provider) {
      case 'gemini':
        response = await _generateBackCardGemini(prompt, model, apiKey);
        break;
      case 'openai':
        response = await _generateBackCardOpenAI(prompt, model, apiKey);
        break;
      case 'deepseek':
        response = await _generateBackCardDeepSeek(prompt, model, apiKey);
        break;
      case 'qianwen':
        response = await _generateBackCardQianwen(prompt, model, apiKey);
        break;
      default:
        throw Exception('Unsupported AI provider: $provider');
    }

    // Parse JSON response
    try {
      // Clean up response - remove markdown code blocks if present
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();
      
      final quiz = jsonDecode(cleanResponse) as Map<String, dynamic>;
      
      // Validate structure
      if (!quiz.containsKey('question') || 
          !quiz.containsKey('options') || 
          !quiz.containsKey('correct')) {
        throw Exception('Invalid quiz format from AI');
      }
      
      return quiz;
    } catch (e) {
      print('[AI Quiz] Failed to parse response: $e');
      print('[AI Quiz] Raw response: $response');
      throw Exception('Failed to parse quiz from AI response: $e');
    }
  }

  String _sanitizeBackCard(String text, String word) {
    if (text.isEmpty) return text;
    String t = text;
    // Remove code fences
    t = t.replaceAll('```json', '');
    t = t.replaceAll('```', '');
    // Split lines and clean
    final lines = t
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
          // Drop markdown bullets and headings
          l = l.replaceFirst(RegExp(r'^[#>*`\-\*•]+\s*'), '');
          // Remove common headings like "Learning Card" or similar
          if (l.toLowerCase() == 'learning card' || 
              l.toLowerCase() == 'study card' ||
              l.toLowerCase() == word.toLowerCase()) {
            return '';
          }
          return l;
        })
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.join('\n');
  }

  /// Generate back card using Google Gemini
  Future<String> _generateBackCardGemini(String prompt, String model, String apiKey) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1024,
        'responseMimeType': 'text/plain'
      },
      'systemInstruction': {
        'parts': [
          {
            'text': 'You are a concise tutor. Provide only the final answer in plain text, exactly as instructed (four lines). Do not include any internal reasoning, preface, or extra commentary.'
          }
        ]
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    print('[AI BackCard][gemini] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      print('[AI BackCard][gemini] raw response (truncated 500): ' + (response.body.length > 500 ? response.body.substring(0,500) : response.body));
    }

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = responseData['candidates'] as List?;
    
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini AI');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    
    if (parts == null || parts.isEmpty) {
      // Gracefully degrade on empty content (e.g., MAX_TOKENS) instead of throwing
      return '';
    }

    final text = parts[0]['text'] as String?;
    if (text == null || text.isEmpty) {
      // Gracefully return empty when provider returns no text
      return '';
    }

    return text.trim();
  }

  /// Generate back card using OpenAI
  Future<String> _generateBackCardOpenAI(String prompt, String model, String apiKey) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 512,
      'temperature': 0.3
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    print('[AI BackCard][openai] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      print('[AI BackCard][openai] raw response (truncated 500): ' + (response.body.length > 500 ? response.body.substring(0,500) : response.body));
    }

    if (response.statusCode != 200) {
      throw Exception('OpenAI API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from OpenAI');
    }

    final content = choices[0]['message']['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Empty response from OpenAI');
    }

    return content.trim();
  }

  /// Generate back card using DeepSeek
  Future<String> _generateBackCardDeepSeek(String prompt, String model, String apiKey) async {
    final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');

    final requestBody = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 512,
      'temperature': 0.3
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    print('[AI BackCard][deepseek] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      print('[AI BackCard][deepseek] raw response (truncated 500): ' + (response.body.length > 500 ? response.body.substring(0,500) : response.body));
    }

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from DeepSeek');
    }

    final content = choices[0]['message']['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Empty response from DeepSeek');
    }

    return content.trim();
  }

  /// Generate back card using Qianwen
  Future<String> _generateBackCardQianwen(String prompt, String model, String apiKey) async {
    final url = Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation');

    final requestBody = {
      'model': model,
      'input': {
        'messages': [
          {'role': 'user', 'content': prompt}
        ]
      },
      'parameters': {
        'max_tokens': 512,
        'temperature': 0.3
      }
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    print('[AI BackCard][qianwen] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      print('[AI BackCard][qianwen] raw response (truncated 500): ' + (response.body.length > 500 ? response.body.substring(0,500) : response.body));
    }

    if (response.statusCode != 200) {
      throw Exception('Qianwen API Error ${response.statusCode}: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final output = responseData['output'] as Map<String, dynamic>?;
    
    if (output == null) {
      throw Exception('No output from Qianwen');
    }

    final text = output['text'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Empty response from Qianwen');
    }

    return text.trim();
  }

  /// Analyze study and quiz history using AI and return a readable report
  /// The input should be a compact JSON text containing period, aggregates,
  /// and a bounded list of records. The provider/model selection follows
  /// current user settings; requires an API key.
  Future<String> analyzeStudyHistory(String analysisPrompt) async {
    final provider = await getAiProvider();
    final model = await getAiModel();
    final apiKey = await getAiApiKey();

    if (apiKey.isEmpty) {
      throw Exception('API key is not configured. Please set it in Settings.');
    }

    print('[AI Analysis] provider=$provider model=$model');
    print('[AI Analysis] prompt length=${analysisPrompt.length}');
    // Printing full prompt to aid debugging; consider truncation if too large
    print('[AI Analysis] prompt: ' + analysisPrompt);

    // Primary attempt based on selected provider, with graceful fallback if empty.
    String result = '';
    try {
      switch (provider) {
        case 'gemini':
          result = await _generateTextGemini(analysisPrompt, model, apiKey, maxTokens: 1500);
          break;
        case 'openai':
          result = await _generateTextOpenAI(analysisPrompt, model, apiKey, maxTokens: 1500);
          break;
        case 'deepseek':
          result = await _generateTextDeepSeek(analysisPrompt, model, apiKey, maxTokens: 1500);
          break;
        case 'qianwen':
          result = await _generateTextQianwen(analysisPrompt, model, apiKey, maxTokens: 1500);
          break;
        default:
          throw Exception('Unsupported AI provider: $provider');
      }
    } catch (e) {
      print('[AI Analysis] primary attempt error: $e');
    }

    if (result.trim().isEmpty) {
      print('[AI Analysis] Empty or failed result from $provider/$model.');
      print('[AI Analysis] Suggestion: Try a different provider or model in Settings, or reduce data period.');
    }
    return result;
  }

  // Generic long-form text generation (analysis/report) for providers
  Future<String> _generateTextGemini(String prompt, String model, String apiKey, {int maxTokens = 1024}) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'
    );
    final requestBody = {
      'contents': [
        {
          'parts': [ {'text': prompt} ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': maxTokens,
        'responseMimeType': 'text/plain'
      },
      'systemInstruction': {
        'parts': [
          { 'text': 'You are a direct assistant. Provide only the final markdown report without any internal reasoning, thinking steps, or analysis process. Be concise and actionable.' }
        ]
      }
    };
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    print('[AI Analysis][gemini] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      final body = response.body;
      print('[AI Analysis][gemini] raw response (truncated 2000): ' + (body.length > 2000 ? body.substring(0,2000) : body));
    }
    if (response.statusCode != 200) {
      throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
    }
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = responseData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';
    final text = parts[0]['text'] as String?;
    return (text ?? '').trim();
  }

  Future<String> _generateTextOpenAI(String prompt, String model, String apiKey, {int maxTokens = 1024}) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final requestBody = {
      'model': model,
      'messages': [ {'role': 'user', 'content': prompt} ],
      'max_tokens': maxTokens,
      'temperature': 0.2,
    };
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    print('[AI Analysis][openai] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      final body = response.body;
      print('[AI Analysis][openai] raw response (truncated 2000): ' + (body.length > 2000 ? body.substring(0,2000) : body));
    }
    if (response.statusCode != 200) {
      throw Exception('OpenAI API Error ${response.statusCode}: ${response.body}');
    }
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final content = choices[0]['message']['content'] as String?;
    return (content ?? '').trim();
  }

  Future<String> _generateTextDeepSeek(String prompt, String model, String apiKey, {int maxTokens = 1024}) async {
    final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');
    final requestBody = {
      'model': model,
      'messages': [ {'role': 'user', 'content': prompt} ],
      'max_tokens': maxTokens,
      'temperature': 0.2,
    };
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    print('[AI Analysis][deepseek] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      final body = response.body;
      print('[AI Analysis][deepseek] raw response (truncated 2000): ' + (body.length > 2000 ? body.substring(0,2000) : body));
    }
    if (response.statusCode != 200) {
      throw Exception('DeepSeek API Error ${response.statusCode}: ${response.body}');
    }
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final content = choices[0]['message']['content'] as String?;
    return (content ?? '').trim();
  }

  Future<String> _generateTextQianwen(String prompt, String model, String apiKey, {int maxTokens = 1024}) async {
    final url = Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation');
    final requestBody = {
      'model': model,
      'input': {
        'messages': [ {'role': 'user', 'content': prompt} ]
      },
      'parameters': {
        'max_tokens': maxTokens,
        'temperature': 0.2
      }
    };
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );
    print('[AI Analysis][qianwen] status=${response.statusCode}');
    if (response.body.isNotEmpty) {
      final body = response.body;
      print('[AI Analysis][qianwen] raw response (truncated 2000): ' + (body.length > 2000 ? body.substring(0,2000) : body));
    }
    if (response.statusCode != 200) {
      throw Exception('Qianwen API Error ${response.statusCode}: ${response.body}');
    }
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final output = responseData['output'] as Map<String, dynamic>?;
    if (output == null) return '';
    final text = output['text'] as String?;
    return (text ?? '').trim();
  }
}
