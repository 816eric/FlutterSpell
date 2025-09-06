import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsHelper {
  static Future<void> playWord({
    required BuildContext context,
    required FlutterTts tts,
    required String word,
    Map<String, String>? currentVoice,
    List<Map<String, String>>? availableVoices,
    int repeatCount = 1,
  }) async {
    await tts.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    // Helper to detect Chinese
    bool isChinese(String s) {
      return RegExp(r'[\u4e00-\u9fff]').hasMatch(s);
    }
    for (int i = 0; i < repeatCount; i++) {
      List<dynamic> voices = await tts.getVoices;
      final voicesList = voices.whereType<Map>().map((v) => Map<String, String>.from(v)).toList();
      final prefs = await SharedPreferences.getInstance();
      final savedVoiceName = prefs.getString('selectedVoice');
      if (isChinese(word)) {
        Map<String, String>? chineseVoice;
        // Prefer user-selected voice if it is a Chinese voice
        if (savedVoiceName != null && voicesList.isNotEmpty) {
          final match = voicesList.firstWhere(
            (v) => v['name'] == savedVoiceName && v['locale'] != null && (
              v['locale']!.contains('zh-CN') || v['locale']!.contains('zh-TW') || v['locale']!.contains('zh-HK')
            ),
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            chineseVoice = match;
          }
        }
        // If user did not set a voice, try Sinij first
        if (chineseVoice == null) {
          final sinijVoice = voicesList.firstWhere(
            (v) => v['name']?.toLowerCase() == 'sinij' && v['locale'] != null && (
              v['locale']!.contains('zh-CN') || v['locale']!.contains('zh-TW') || v['locale']!.contains('zh-HK')
            ),
            orElse: () => {},
          );
          if (sinijVoice.isNotEmpty) {
            chineseVoice = sinijVoice;
          }
        }
        // Fallback to auto-detect if not found
        if (chineseVoice == null) {
          for (var v in voices) {
            if (v is Map && v['locale'] != null && v['locale'].toString().contains('zh-CN')) {
              chineseVoice = Map<String, String>.from(v);
              break;
            }
          }
          if (chineseVoice == null) {
            for (var v in voices) {
              if (v is Map && v['locale'] != null && v['locale'].toString().contains('zh-TW')) {
                chineseVoice = Map<String, String>.from(v);
                break;
              }
            }
          }
          if (chineseVoice == null) {
            for (var v in voices) {
              if (v is Map && v['locale'] != null && v['locale'].toString().contains('zh-HK')) {
                chineseVoice = Map<String, String>.from(v);
                break;
              }
            }
          }
        }
        if (chineseVoice != null) {
          await tts.setVoice(chineseVoice);
          await tts.setLanguage(chineseVoice['locale']!);
        } else {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('No Chinese TTS Voice Found'),
                content: const Text('No Chinese (Mandarin/Taiwanese/HK) voice is installed on your device. Please install a Chinese voice in your system settings.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } else {
        await tts.setLanguage("en-US");
        Map<String, String>? usedVoice;
        if (savedVoiceName != null && voicesList.isNotEmpty) {
          final match = voicesList.firstWhere(
            (v) => v['name'] == savedVoiceName,
            orElse: () => voicesList[0],
          );
          await tts.setVoice(match);
          usedVoice = match;
        } else if (currentVoice != null) {
          await tts.setVoice(currentVoice);
          usedVoice = currentVoice;
        }
      }
      await tts.speak(word);
      for (int j = 0; j < 50; j++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
