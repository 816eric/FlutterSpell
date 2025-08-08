import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/spell_api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StudyPage extends StatefulWidget {
  final String userName;
  const StudyPage({super.key, required this.userName});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<dynamic> tags = [];
  List<dynamic> words = [];
  int currentIndex = 0;
  String? selectedTag;
  final FlutterTts tts = FlutterTts();

  Future<void> loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString("cached_tags_${widget.userName}");
    if (cached != null) {
      tags = json.decode(cached);
    } else {
      tags = await SpellApiService.getUserTags(widget.userName);
      prefs.setString("cached_tags_${widget.userName}", json.encode(tags));
    }
    setState(() {});
  }

  Future<void> loadWords(String tag) async {
    words = await SpellApiService.getWords(widget.userName, tag);
    setState(() {
      currentIndex = 0;
    });
  }

  void playCurrentWord() {
    if (words.isNotEmpty) {
      final word = words[currentIndex]["text"];
      tts.speak(word);
    }
  }

  void nextWord() {
    setState(() {
      currentIndex = (currentIndex + 1) % words.length;
    });
    playCurrentWord();
  }

  void previousWord() {
    setState(() {
      currentIndex = (currentIndex - 1 + words.length) % words.length;
    });
    playCurrentWord();
  }

  @override
  void initState() {
    super.initState();
    loadTags();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = words.isNotEmpty ? words[currentIndex]["text"] : "";

    return Scaffold(
      appBar: AppBar(title: const Text("Study Words")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedTag,
              hint: const Text("Select tag"),
              items: tags
                  .where((tag) => tag != null && (tag["tag"] != null && tag["tag"] is String))
                  .map<DropdownMenuItem<String>>((tag) {
                final String tagName = tag["tag"] as String;
                return DropdownMenuItem<String>(
                  value: tagName,
                  child: Text(tagName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedTag = value);
                  loadWords(value);
                }
              },
            ),
            const SizedBox(height: 20),
            Text(currentWord, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: previousWord, child: const Text("Previous")),
                ElevatedButton(onPressed: playCurrentWord, child: const Text("Play")),
                ElevatedButton(onPressed: nextWord, child: const Text("Next")),
              ],
            )
          ],
        ),
      ),
    );
  }
}