import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/tts_stub.dart'
    if (dart.library.js_util) '../services/tts_web.dart';
import '../services/spell_api_service.dart';
import '../services/tts_helper.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showWord = false;
  String? _effectiveUserName;
  int _playSession = 0;
  final FlutterTts tts = FlutterTts();
  List<String> tags = [];
  String? selectedTag;
  List<Map<String, dynamic>> words = [];
  int currentIndex = 0;
  int points = 0;
  Map<String, String>? currentVoice;
  List<Map<String, String>> availableVoices = [];

  @override
  void initState() {
    super.initState();
    initTTS();
    _effectiveUserName = (widget.userName.isEmpty) ? 'Guest' : widget.userName;
    fetchUserData();
  }

  Future<void> initTTS() async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(1); // Set speech rate slower (default is 0.5-1.0)
    await tts.awaitSpeakCompletion(true);
    List<dynamic> voices = await tts.getVoices;
    availableVoices = voices.whereType<Map>().map((v) => Map<String, String>.from(v)).toList();
    // Load selected voice from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedVoiceName = prefs.getString('selectedVoice');
    if (savedVoiceName != null) {
      final match = availableVoices.firstWhere(
        (v) => v['name'] == savedVoiceName,
        orElse: () => availableVoices.isNotEmpty ? availableVoices[0] : {},
      );
      if (match.isNotEmpty) {
        currentVoice = match;
        await tts.setVoice(currentVoice!);
      }
    } else {
      for (var voice in availableVoices) {
        if (voice.containsKey("name") && voice["name"]!.contains("Zira")) {
          currentVoice = voice;
          await tts.setVoice(currentVoice!);
          break;
        }
      }
    }
  }

  Future<void> fetchUserData() async {
    String user = _effectiveUserName ?? 'Guest';
    try {
      // Only fetch profile if user is not empty and not 'Guest'
      Map<String, dynamic> profile = {};
      String tagUser = (user.isEmpty || user == 'Guest') ? 'admin' : user;
      if (user.isNotEmpty && user != 'Guest') {
        profile = await SpellApiService.getUserProfile(user);
      }
      // Always use getUserTags, but use 'admin' for Guest/empty
      final userTags = await SpellApiService.getUserTags(tagUser);
      print(userTags);
      String? latestTag;
      try {
        latestTag = await SpellApiService.getLatestLoginTag(user);
      } catch (_) {
        latestTag = null;
      }
      // Always use tag names for Dropdown
      final tagNames = userTags.map((e) => e['tag'] as String).toList();
      String? preselectTag = (latestTag != null && tagNames.contains(latestTag)) ? latestTag : (tagNames.isNotEmpty ? tagNames[0] : null);
      setState(() {
        _effectiveUserName = user;
        points = profile['total_points'] ?? 0;
        tags = tagNames;
        selectedTag = preselectTag;
      });
      if (preselectTag != null) {
        fetchWords(preselectTag);
      }
    } catch (e) {
      setState(() {
        _effectiveUserName = 'Guest';
        points = 0;
        tags = [];
        selectedTag = null;
      });
    }
  }

  Future<void> fetchWords(String tag) async {
    // If user is Guest, fetch words as Admin
    final user = (_effectiveUserName == null || _effectiveUserName == 'Guest') ? 'admin' : _effectiveUserName!;
    final fetchedWords = await SpellApiService.getWords(user, tag);
    setState(() {
      words = fetchedWords;
      currentIndex = 0;
    });
  }

  Future<void> _playWord() async {
    if (words.isEmpty) return;
    final word = words[currentIndex]['text'];
    await TtsHelper.playWord(
      context: context,
      tts: tts,
      word: word,
      currentVoice: currentVoice,
      availableVoices: availableVoices,
      repeatCount: 3,
    );
  }

  void _goPrevious() async {
    if (words.isEmpty) return;
    await tts.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      currentIndex = (currentIndex - 1 + words.length) % words.length;
      _showWord = false;
    });
    await _playWord();
  }

  void _goNext() async {
    if (words.isEmpty) return;
    await tts.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      currentIndex = (currentIndex + 1) % words.length;
      _showWord = false;
    });
    await _playWord();
  }

  @override
  Widget build(BuildContext context) {
    final word = words.isNotEmpty ? words[currentIndex]['text'] : '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spell Practice'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("👋 Hello, ${_effectiveUserName ?? 'Guest'}! You have $points points.",
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownButton<String>(
                      value: selectedTag,
                      hint: const Text("Select Tag"),
                      isExpanded: true,
                      items: tags.map((tag) {
                        return DropdownMenuItem(value: tag, child: Text(tag));
                      }).toList(),
                      onChanged: (tag) {
                        if (tag != null) {
                          setState(() {
                            selectedTag = tag;
                          });
                          SpellApiService.logLoginHistory(widget.userName, tag: tag);
                          fetchWords(tag);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                if (!_showWord)
                  SizedBox(
                    width: 200, 
                    height: 40,
                    child: ElevatedButton(
                      onPressed: words.isNotEmpty ? () => setState(() => _showWord = true) : null,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 13), 
                      ),
                      child: const Text("Show me the word"),
                    ),
                  )
                else
                  Text(
                    word,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 32),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100, height: 36, // half size
                      child: ElevatedButton(
                        onPressed: _goPrevious,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 20), 
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                        child: const Text("Previous"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 100, height: 36,
                      child: ElevatedButton(
                        onPressed: _playWord,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 20),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                        child: const Text("Play"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 100, height: 36,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 20),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                        child: const Text("Next"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}