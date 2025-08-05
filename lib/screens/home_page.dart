import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/tts_stub.dart'
    if (dart.library.js_util) '../services/tts_web.dart';
import '../services/spell_api_service.dart';

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
  String? currentVoice;

  @override
  void initState() {
    super.initState();
    initTTS();
    _effectiveUserName = (widget.userName.isEmpty) ? 'Guest' : widget.userName;
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
    String user = _effectiveUserName ?? 'Guest';
    try {
      // Only fetch profile if user is not empty and not 'Guest'
      Map<String, dynamic> profile = {};
      // If user is empty or Guest, fetch tags as Admin
      final isGuest = user.isEmpty || user == 'Guest';
      if (!isGuest) {
        profile = await SpellApiService.getUserProfile(user);
      }
      
      final userTags = isGuest
          ? await SpellApiService.getAdminTags()
          : await SpellApiService.getUserTags(user);
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
    _playSession++;
    final int session = _playSession;
    final word = words[currentIndex]['text'];

    for (int i = 0; i < 3; i++) {
      if (kIsWeb) {
        await playWordWeb(word);
        print("Web SpeechSynthesis called for: $word");
      } else {
        await tts.stop();
        final result = await tts.speak(word);
        print("TTS Speak Result: $result");
      }
      // Wait for 5 seconds before next repeat, but break if session is outdated
      for (int j = 0; j < 50; j++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_playSession != session) return;
      }
    }
  }

  void _goPrevious() async {
    if (words.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex - 1 + words.length) % words.length;
      _showWord = false;
    });
    await _playWord();
  }

  void _goNext() async {
    if (words.isEmpty) return;
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
                      SpellApiService.logLoginHistory(widget.userName, tag: tag);
                      fetchWords(tag);
                    }
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