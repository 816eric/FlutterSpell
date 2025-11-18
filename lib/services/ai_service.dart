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
  static const String _defaultModel = 'gemini-2.5-flash';

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
        return 'gemini-2.5-flash';
      case 'openai':
        return 'gpt-4o-mini';
      case 'deepseek':
        return 'deepseek-chat';
      case 'qianwen':
        return 'qwen-turbo';
      default:
        return 'gemini-2.0-flash-exp';
    }
  }

  /// Get available models for a provider
  static List<String> getModelsForProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return [
          'gemini-2.5-flash',
          'gemini-2.0-flash-exp',
          'gemini-1.5-flash',
          'gemini-1.5-pro',
          'gemini-1.0-pro',
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
}
