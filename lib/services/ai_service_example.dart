/// Example usage of AIService for Spell Application
/// 
/// This file demonstrates how to integrate the AI service
/// for extracting words from images in your application.

import 'package:image_picker/image_picker.dart';
import 'ai_service.dart';

/// Example 1: Extract words from an image picked by the user
Future<void> extractWordsExample() async {
  // Initialize the AIService (singleton)
  final aiService = AIService();
  
  // Pick an image from gallery
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    try {
      // Extract words using the configured AI provider
      final words = await aiService.extractWordsFromImage(pickedFile);
      
      // Use the extracted words
      print('Extracted words: $words');
      
      // Example: Join words with commas
      final wordText = words.join(', ');
      print('Word text: $wordText');
      
    } catch (e) {
      print('Error extracting words: $e');
      
      // Handle specific errors
      if (e.toString().contains('API key is not configured')) {
        print('Please configure your API key in Settings');
      }
    }
  }
}

/// Example 2: Check current AI configuration
Future<void> checkAiConfigExample() async {
  final aiService = AIService();
  
  // Get current settings
  final provider = await aiService.getAiProvider();
  final model = await aiService.getAiModel();
  final apiKey = await aiService.getAiApiKey();
  
  print('Current AI Provider: $provider');
  print('Current AI Model: $model');
  print('API Key configured: ${apiKey.isNotEmpty}');
}

/// Example 3: Change AI provider programmatically
Future<void> changeAiProviderExample() async {
  final aiService = AIService();
  
  // Change to OpenAI
  await aiService.setAiProvider('openai');
  await aiService.setAiModel('gpt-4o-mini');
  await aiService.setAiApiKey('your-openai-api-key');
  
  print('AI provider changed to OpenAI');
}

/// Example 4: Integration in My Words Page
/// 
/// Replace the existing extractWordsFromImageWeb call with:
/// 
/// ```dart
/// if (kIsWeb) {
///   // Web: Use AI Service
///   try {
///     final aiService = AIService();
///     final words = await aiService.extractWordsFromImage(pickedFile);
///     extractedText = words.join(', ');
///   } catch (e) {
///     extractedText = "[Failed to extract text: $e]";
///   }
/// }
/// ```
/// 
/// This will automatically use the AI provider configured in Settings.
