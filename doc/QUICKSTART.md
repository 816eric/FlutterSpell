# AI Service Quick Start Guide

This guide will help you get started with the AI Service in under 5 minutes.

## Step 1: Choose Your AI Provider

Pick one of these providers and get an API key:

### Option A: Google Gemini (Recommended for Beginners)
1. Visit https://ai.google.dev
2. Sign in with Google account
3. Click "Get API Key"
4. Copy the key (starts with `AIza...`)
5. **FREE TIER**: 15 requests/minute

### Option B: OpenAI (Most Reliable)
1. Visit https://platform.openai.com
2. Sign up / Sign in
3. Go to API Keys section
4. Create new secret key
5. Copy the key (starts with `sk-...`)
6. **COST**: ~$0.0005 per image

### Option C: DeepSeek (Most Affordable)
1. Visit https://platform.deepseek.com
2. Sign up / Sign in
3. Navigate to API Keys
4. Generate new key
5. **COST**: ~$0.0001 per image

### Option D: Qianwen (Best for Chinese)
1. Visit Alibaba Cloud Console
2. Navigate to DashScope
3. Create API key
4. **GOOD FOR**: Chinese + English content

## Step 2: Configure in App

### Via Settings UI (Easiest)
1. Open the Spell app
2. Go to **Settings** page
3. Tap on **AI Configuration** card
4. Select your **AI Provider**
5. Choose a **Model** (default is fine)
6. Paste your **API Key**
7. Tap **Save** icon (or it saves automatically)
8. Optionally tap **Test Configuration** to verify

### Via Code (For Testing)
```dart
import 'package:spell/services/ai_service.dart';

// One-time setup
final aiService = AIService();
await aiService.setAiProvider('gemini');
await aiService.setAiModel('gemini-2.0-flash-exp');
await aiService.setAiApiKey('YOUR_API_KEY_HERE');
```

## Step 3: Test It

### Using My Words Page
1. Go to **My Words** page
2. Tap the **camera icon** or **upload button**
3. Select an image with English words
4. Wait 2-5 seconds
5. See extracted words appear!

### Using Code
```dart
import 'package:image_picker/image_picker.dart';
import 'package:spell/services/ai_service.dart';

// Pick an image
final picker = ImagePicker();
final image = await picker.pickImage(source: ImageSource.gallery);

// Extract words
if (image != null) {
  final aiService = AIService();
  try {
    final words = await aiService.extractWordsFromImage(image);
    print('Found ${words.length} words: $words');
  } catch (e) {
    print('Error: $e');
  }
}
```

## Common Issues & Solutions

### ❌ "API key is not configured"
**Solution**: Make sure you've entered the API key in Settings → AI Configuration

### ❌ "No response from AI"
**Solution**: 
- Check your internet connection
- Verify API key is correct
- Try a different AI provider

### ❌ "Failed to parse response"
**Solution**:
- Try a different model
- Ensure image contains clear text
- Check if image is too complex

### ❌ Image too large
**Solution**: The service automatically compresses images, but if it still fails:
- Use smaller images
- Ensure image format is supported (JPEG, PNG, GIF, WebP)

## Quick Reference

### Recommended Configurations

**For Free Usage:**
```
Provider: Gemini
Model: gemini-2.0-flash-exp
API Key: Get from ai.google.dev
```

**For Production:**
```
Provider: OpenAI
Model: gpt-4o-mini
API Key: Get from platform.openai.com
```

**For Budget:**
```
Provider: DeepSeek
Model: deepseek-chat
API Key: Get from platform.deepseek.com
```

**For Bilingual:**
```
Provider: Qianwen
Model: qwen-turbo
API Key: Get from Alibaba Cloud
```

## Testing Checklist

- [ ] API key entered in Settings
- [ ] Provider selected
- [ ] Model selected (or using default)
- [ ] Internet connection active
- [ ] Test image prepared (with clear text)
- [ ] Camera/gallery permissions granted
- [ ] Test extraction works
- [ ] Words display correctly

## Performance Tips

1. **Use appropriate models**:
   - Simple images → Fast models (gemini-2.0-flash-exp, gpt-4o-mini)
   - Complex images → Advanced models (gemini-1.5-pro, gpt-4o)

2. **Optimize images**:
   - Use clear, high-contrast images
   - Ensure text is legible
   - Avoid blurry or rotated images

3. **Monitor usage**:
   - Check provider dashboards for usage
   - Set up billing alerts if using paid providers
   - Consider free tiers for testing

## Next Steps

1. ✅ Configure your API key (you're here!)
2. 📸 Test with a few images
3. 🔄 Try different providers
4. 📊 Monitor accuracy and performance
5. 🚀 Integrate into your workflow

## Need Help?

### Read the Docs
- **README**: `AI_SERVICE_README.md` - Comprehensive documentation
- **Architecture**: `AI_SERVICE_ARCHITECTURE.md` - System design
- **Summary**: `AI_SERVICE_SUMMARY.md` - Overview and features
- **Examples**: `lib/services/ai_service_example.dart` - Code samples

### Common Code Patterns

**Check if configured:**
```dart
final aiService = AIService();
final apiKey = await aiService.getAiApiKey();
if (apiKey.isEmpty) {
  // Show settings dialog
  print('Please configure AI settings');
}
```

**Switch provider:**
```dart
// Change to OpenAI
await aiService.setAiProvider('openai');
await aiService.setAiModel('gpt-4o-mini');
```

**Handle errors gracefully:**
```dart
try {
  final words = await aiService.extractWordsFromImage(image);
  // Success!
} catch (e) {
  if (e.toString().contains('API key')) {
    // Show settings prompt
  } else if (e.toString().contains('network')) {
    // Show retry option
  } else {
    // Show generic error
  }
}
```

## API Key Security

⚠️ **Important Security Notes:**

1. **Never commit API keys to Git**
   ```dart
   // ❌ BAD
   final apiKey = 'sk-1234567890abcdef';
   
   // ✅ GOOD
   final apiKey = await AIService().getAiApiKey();
   ```

2. **For production apps:**
   - Use environment variables
   - Implement key rotation
   - Monitor usage
   - Set spending limits

3. **For personal use:**
   - Store keys in Settings (as implemented)
   - Don't share your API keys
   - Regenerate if compromised

## Success Indicators

You'll know it's working when:
- ✅ Settings UI shows your configuration
- ✅ Image upload shows processing indicator
- ✅ Words appear in the text field
- ✅ No error messages displayed
- ✅ Extraction completes in 2-7 seconds

## Troubleshooting Commands

**Clear settings and start fresh:**
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('ai_provider');
await prefs.remove('ai_model');
await prefs.remove('ai_api_key');
```

**Check current configuration:**
```dart
final aiService = AIService();
print('Provider: ${await aiService.getAiProvider()}');
print('Model: ${await aiService.getAiModel()}');
print('API Key set: ${(await aiService.getAiApiKey()).isNotEmpty}');
```

**Force cache refresh:**
```dart
final aiService = AIService();
aiService.clearCache();
```

---

**Ready to start?** Open Settings and configure your first AI provider! 🚀
