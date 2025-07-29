import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:js_util' as js_util;
import '../services/spell_api_service.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts tts = FlutterTts();
  List<String> tags = [];
  String? selectedTag;
  List<Map<String, dynamic>> words = [];
  int currentIndex = 0;
  int points = 0;
  String? currentVoice;

  @override
  void initState() {
    super.initState();
    initTTS();
    fetchUserData();
  }

  Future<void> initTTS() async {
    await tts.setLanguage("en-US");
    await tts.awaitSpeakCompletion(true);
    List<dynamic> voices = await tts.getVoices;
    for (var voice in voices) {
      if (voice is Map && voice.containsKey("name") && voice["name"].toString().contains("Zira")) {
        currentVoice = voice["name"];
        await tts.setVoice(Map<String, String>.from(voice));
        break;
      }
    }
  }

  Future<void> fetchUserData() async {
    final profile = await SpellApiService.getUserProfile("Eric");
    final userTags = await SpellApiService.getUserTags(widget.userName);
    setState(() {
      points = profile['total_points'] ?? 0;
      tags = List<String>.from(userTags);
    });
  }

  Future<void> fetchWords(String tag) async {
    final fetchedWords = await SpellApiService.getWords(widget.userName, [tag]);
    setState(() {
      words = fetchedWords;
      currentIndex = 0;
    });
  }

  Future<void> _playWord() async {
    if (words.isNotEmpty) {
      final word = words[currentIndex]['text'];
      // Web: use SpeechSynthesis API
      if (identical(0, 0.0)) { // kIsWeb
        try {
          final synth = js_util.getProperty(js_util.globalThis, 'speechSynthesis');
          final voices = js_util.callMethod(synth, 'getVoices', []);
          final voicesList = List.from(voices);
          // Detect if the word contains Chinese characters
          final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(word);
          var selectedVoice;
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
          final utter = js_util.callConstructor(
            js_util.getProperty(js_util.globalThis, 'SpeechSynthesisUtterance'),
            [word],
          );
          if (selectedVoice != null) {
            js_util.setProperty(utter, 'voice', selectedVoice);
            js_util.setProperty(utter, 'lang', js_util.getProperty(selectedVoice, 'lang'));
          }
          js_util.callMethod(synth, 'speak', [utter]);
          print("Web SpeechSynthesis called for: $word");
        } catch (e) {
          print("Web TTS Error: $e");
        }
      } else {
        final result = await tts.speak(word);
        print("TTS Speak Result: $result");
      }
    }
  }

  void _goPrevious() async {
    if (words.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex - 1 + words.length) % words.length;
    });
    await _playWord();
  }

  void _goNext() async {
    if (words.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % words.length;
    });
    await _playWord();
  }

  @override
  Widget build(BuildContext context) {
    final word = words.isNotEmpty ? words[currentIndex]['text'] : 'Select a tag';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spell Practice'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("👋 Hello, \${widget.userName}! You have \$points points.",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedTag,
              hint: const Text("Select Tag"),
              items: tags.map((tag) {
                return DropdownMenuItem(value: tag, child: Text(tag));
              }).toList(),
              onChanged: (tag) {
                if (tag != null) {
                  setState(() {
                    selectedTag = tag;
                  });
                  fetchWords(tag);
                }
              },
            ),
            const SizedBox(height: 32),
            Text(
              word,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _goPrevious, child: const Text("Previous")),
                ElevatedButton(onPressed: _playWord, child: const Text("Play")),
                ElevatedButton(onPressed: _goNext, child: const Text("Next")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}