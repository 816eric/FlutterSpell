import 'dart:js_util' as js_util;
import 'dart:html' as html;
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keep track of currently playing audio to allow stopping
html.AudioElement? _currentAudio;

/// Check if the device is mobile (iOS/Android)
bool _isMobileDevice() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') || 
         userAgent.contains('ipad') || 
         userAgent.contains('android');
}

Future<void> playWordWeb(String word) async {
  // Stop any currently playing audio (Google Cloud TTS)
  if (_currentAudio != null) {
    _currentAudio!.pause();
    _currentAudio!.currentTime = 0;
    _currentAudio = null;
  }
  
  // Also cancel any browser TTS that might be playing
  try {
    final synth = js_util.getProperty(js_util.globalThis, 'speechSynthesis');
    js_util.callMethod(synth, 'cancel', []);
  } catch (e) {
    // Ignore if speechSynthesis not available
  }
  
  // For mobile devices (iPhone/Android): Use Google Cloud TTS with fallback
  // For desktop/PC: Use browser TTS directly
  if (_isMobileDevice()) {
    print('=== TTS: Mobile device detected, using Google Cloud TTS ===');
    final googleTtsSuccess = await _tryGoogleTTS(word);
    
    if (!googleTtsSuccess) {
      // Fallback to browser TTS
      print('=== TTS: Google TTS failed, falling back to browser TTS ===');
      await _playWithBrowserTTS(word);
    }
  } else {
    // Desktop/PC: Use browser TTS directly
    print('=== TTS: Desktop device, using browser TTS ===');
    await _playWithBrowserTTS(word);
  }
}

/// Try to play word using Google Cloud TTS via backend
Future<bool> _tryGoogleTTS(String word) async {
  try {
    // Ensure any previous audio is completely stopped
    if (_currentAudio != null) {
      _currentAudio!.pause();
      _currentAudio!.currentTime = 0;
      _currentAudio = null;
    }
    
    final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(word);
    final lang = isChinese ? 'zh-CN' : 'en-US';
    
    // URL encode the text
    final encodedWord = Uri.encodeComponent(word);
    final url = '${ApiConfig.baseUrl}api/tts/speak?text=$encodedWord&lang=$lang';
    
    // Create and play audio element
    final audioElement = html.AudioElement(url);
    audioElement.volume = 1.0; // Full volume
    
    // Store reference to current audio for stopping
    _currentAudio = audioElement;
    
    // Wait for the audio to be ready
    await audioElement.onCanPlay.first;
    
    // Play the audio
    await audioElement.play();
    
    // Wait for playback to complete
    await audioElement.onEnded.first;
    
    // Clear reference when done
    if (_currentAudio == audioElement) {
      _currentAudio = null;
    }
    
    return true;
  } catch (e) {
    // Google TTS failed
    print('Google TTS error: $e');
    _currentAudio = null;
    return false;
  }
}

/// Fallback: Use browser's built-in speech synthesis
Future<void> _playWithBrowserTTS(String word) async {
  final synth = js_util.getProperty(js_util.globalThis, 'speechSynthesis');
  
  // Cancel any ongoing speech
  js_util.callMethod(synth, 'cancel', []);
  
  final voices = js_util.callMethod(synth, 'getVoices', []);
  final voicesList = List.from(voices);
  final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(word);
  
  // Try to get saved voice preference
  final prefs = await SharedPreferences.getInstance();
  final savedVoiceName = prefs.getString('selectedBrowserVoice');
  
  var selectedVoice;
  
  // First, try to use saved voice if available
  if (savedVoiceName != null && savedVoiceName.isNotEmpty) {
    selectedVoice = voicesList.firstWhere(
      (v) => js_util.getProperty(v, 'name').toString() == savedVoiceName,
      orElse: () => null,
    );
  }
  
  // If no saved voice or saved voice not found, auto-select by language
  if (selectedVoice == null) {
    if (isChinese) {
      selectedVoice = voicesList.firstWhere(
        (v) => js_util.getProperty(v, 'lang').toString().startsWith('zh'),
        orElse: () => voicesList.isNotEmpty ? voicesList[0] : null,
      );
    } else {
      selectedVoice = voicesList.firstWhere(
        (v) => js_util.getProperty(v, 'lang').toString().startsWith('en'),
        orElse: () => voicesList.isNotEmpty ? voicesList[0] : null,
      );
    }
  }
  
  final utter = js_util.callConstructor(
    js_util.getProperty(js_util.globalThis, 'SpeechSynthesisUtterance'),
    [word],
  );
  
  if (selectedVoice != null) {
    js_util.setProperty(utter, 'voice', selectedVoice);
    js_util.setProperty(utter, 'lang', js_util.getProperty(selectedVoice, 'lang'));
  }
  
  js_util.callMethod(synth, 'speak', [utter]);
}

/// Get available browser voices for selection in settings
List<Map<String, String>> getBrowserVoices() {
  try {
    final synth = js_util.getProperty(js_util.globalThis, 'speechSynthesis');
    final voices = js_util.callMethod(synth, 'getVoices', []);
    final voicesList = List.from(voices);
    
    return voicesList.map((v) {
      return {
        'name': js_util.getProperty(v, 'name').toString(),
        'lang': js_util.getProperty(v, 'lang').toString(),
        'localService': js_util.getProperty(v, 'localService').toString(),
      };
    }).toList();
  } catch (e) {
    print('Error getting browser voices: $e');
    return [];
  }
}
