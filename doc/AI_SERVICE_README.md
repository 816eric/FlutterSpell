# AI Service for Spell Application

This document describes the AI service implementation for the Spell application, which supports multiple AI providers for extracting words from images.

## Overview

The AI service provides a unified interface for image-to-text word extraction using various AI providers. Users can configure their preferred AI provider, model, and API key through the Settings page.

## Supported AI Providers

### 1. Google Gemini (Default)
- **Provider ID**: `gemini`
- **Default Model**: `gemini-2.0-flash-exp`
- **Available Models**:
  - `gemini-2.0-flash-exp` - Latest experimental flash model
  - `gemini-1.5-flash` - Fast, efficient for most tasks
  - `gemini-1.5-pro` - More capable, higher quality
  - `gemini-1.0-pro` - Stable legacy model
- **API Key**: Get from [Google AI Studio](https://ai.google.dev)
- **Features**: Vision + language understanding, best for image analysis

### 2. OpenAI
- **Provider ID**: `openai`
- **Default Model**: `gpt-4o-mini`
- **Available Models**:
  - `gpt-4o-mini` - Cost-effective, fast
  - `gpt-4o` - Most capable multimodal model
  - `gpt-4-turbo` - Fast and capable
  - `gpt-3.5-turbo` - Legacy, cost-effective
- **API Key**: Get from [OpenAI Platform](https://platform.openai.com)
- **Features**: Strong vision capabilities, reliable

### 3. DeepSeek
- **Provider ID**: `deepseek`
- **Default Model**: `deepseek-chat`
- **Available Models**:
  - `deepseek-chat` - General purpose
  - `deepseek-coder` - Code-focused
  - `deepseek-reasoner` - Enhanced reasoning
- **API Key**: Get from [DeepSeek Platform](https://platform.deepseek.com)
- **Features**: Cost-effective alternative

### 4. Qianwen (Alibaba)
- **Provider ID**: `qianwen`
- **Default Model**: `qwen-turbo`
- **Available Models**:
  - `qwen-turbo` - Fast and efficient
  - `qwen-plus` - Balanced performance
  - `qwen-max` - Most capable
  - `qwen-coder-turbo` - Code-focused
- **API Key**: Get from Alibaba Cloud Console
- **Features**: Good for Chinese + English content

## File Structure

```
lib/
├── services/
│   ├── ai_service.dart              # Main AI service implementation
│   ├── ai_service_example.dart      # Usage examples
│   └── spell_api_service.dart       # Existing API service (uses backend)
└── screens/
    └── settings.dart                # Settings page with AI configuration UI
```

## Implementation Details

### AIService Class

The `AIService` class is implemented as a singleton and provides:

1. **Configuration Management**
   - Stores settings in SharedPreferences
   - Provides getters/setters for provider, model, and API key
   - Caches settings for performance

2. **Image Processing**
   - Automatic image compression (max 512KB)
   - Supports File and XFile input
   - Handles multiple image formats (JPEG, PNG, GIF, WebP)

3. **Provider-Specific Methods**
   - `_extractWordsGemini()` - Google Gemini API integration
   - `_extractWordsOpenAI()` - OpenAI API integration
   - `_extractWordsDeepSeek()` - DeepSeek API integration
   - `_extractWordsQianwen()` - Qianwen API integration

### Settings UI

The Settings page includes an expandable AI Configuration section that allows users to:

1. Select AI provider (Gemini, OpenAI, DeepSeek, Qianwen)
2. Choose from available models for each provider
3. Enter and save API keys securely (obscured input)
4. View helpful hints for obtaining API keys

## Usage

### Basic Usage

```dart
import 'package:spell/services/ai_service.dart';
import 'package:image_picker/image_picker.dart';

// Pick an image
final picker = ImagePicker();
final pickedFile = await picker.pickImage(source: ImageSource.gallery);

if (pickedFile != null) {
  try {
    // Extract words using configured AI provider
    final aiService = AIService();
    final words = await aiService.extractWordsFromImage(pickedFile);
    
    print('Extracted words: $words');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Configuration

```dart
final aiService = AIService();

// Get current configuration
final provider = await aiService.getAiProvider();
final model = await aiService.getAiModel();
final apiKey = await aiService.getAiApiKey();

// Change configuration
await aiService.setAiProvider('openai');
await aiService.setAiModel('gpt-4o-mini');
await aiService.setAiApiKey('your-api-key');
```

### Integration with My Words Page

Update the image extraction logic in `my_words_page.dart`:

```dart
if (kIsWeb) {
  // Use AI Service instead of backend
  try {
    final aiService = AIService();
    final words = await aiService.extractWordsFromImage(pickedFile);
    extractedText = words.join(', ');
  } catch (e) {
    extractedText = "[Failed to extract text: $e]";
  }
}
```

## Error Handling

The service throws exceptions with descriptive messages:

- **API key not configured**: "API key is not configured. Please set it in Settings."
- **Unsupported image source**: "Unsupported image source type"
- **Image file not found**: "Image file does not exist"
- **API errors**: "API Error [status_code]: [error_message]"
- **Parse errors**: "Failed to parse [provider] response: [error]"

## Image Compression

Images larger than 512KB are automatically compressed to reduce API costs and improve performance:

1. Calculates required scale factor
2. Resizes image while maintaining aspect ratio
3. Encodes as JPEG with adjustable quality (85 → 30)
4. Ensures final size is under 512KB

## API Request Format

### Gemini
```json
{
  "contents": [{
    "parts": [
      {"text": "Extract all English words..."},
      {"inline_data": {"mime_type": "image/jpeg", "data": "<base64>"}}
    ]
  }]
}
```

### OpenAI/DeepSeek
```json
{
  "model": "gpt-4o-mini",
  "messages": [{
    "role": "user",
    "content": [
      {"type": "text", "text": "Extract all English words..."},
      {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,<base64>"}}
    ]
  }]
}
```

### Qianwen
```json
{
  "model": "qwen-turbo",
  "input": {
    "messages": [{
      "role": "user",
      "content": [
        {"text": "Extract all English words..."},
        {"image": "data:image/jpeg;base64,<base64>"}
      ]
    }]
  }
}
```

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  image: ^4.1.7           # For image compression
  image_picker: ^1.2.0    # For picking images
  http: ^1.5.0            # For API calls
  shared_preferences: ^2.4.11  # For storing settings
```

## Testing

1. Configure API key in Settings → AI Configuration
2. Select desired AI provider and model
3. Go to My Words page
4. Pick an image with text
5. Verify words are extracted correctly

## Comparison with Backend Approach

| Feature | AIService (Direct) | Backend API |
|---------|-------------------|-------------|
| Configuration | User-controlled | Fixed |
| Providers | 4 options | Gemini only |
| API Keys | User's own | Shared backend |
| Costs | Per user | Shared |
| Privacy | Data sent directly | Via backend |
| Flexibility | High | Limited |

## Migration Guide

To switch from backend API to AIService:

1. Install dependencies (add `image` package)
2. Configure AI settings in Settings page
3. Update `my_words_page.dart` to use `AIService.extractWordsFromImage()`
4. Test with each supported provider

## Future Enhancements

1. **Batch Processing**: Extract words from multiple images
2. **Language Support**: Add support for Chinese character extraction
3. **Caching**: Cache results to avoid duplicate API calls
4. **Analytics**: Track usage statistics per provider
5. **Custom Prompts**: Allow users to customize extraction prompts
6. **Offline Mode**: Local OCR fallback when no API key configured

## Troubleshooting

**Problem**: "API key is not configured"
- **Solution**: Go to Settings → AI Configuration and enter your API key

**Problem**: "No word list found in response"
- **Solution**: The AI returned unexpected format. Try a different model or provider.

**Problem**: Image too large error
- **Solution**: The compression should handle this automatically. Check image format.

**Problem**: API rate limits
- **Solution**: Switch to a different provider or implement request throttling

## License

This implementation is part of the Spell application and follows the same license.
