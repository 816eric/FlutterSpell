import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';

class StudyPage extends StatefulWidget {
  final String userName;
  const StudyPage({required this.userName});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<Map<String, dynamic>> words = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void _loadWords() async {
    final result = await SpellApiService().fetchWords(widget.userName, ['grade::Primary1']);
    setState(() => words = result);
  }

  void _studyWord(int wordId) async {
    await SpellApiService().logStudy(widget.userName, wordId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Studied!")));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return ListTile(
          title: Text(word['text']),
          subtitle: Text("Language: ${word['language']} | Tags: ${word['tags'] ?? 'None'}"),
          trailing: ElevatedButton(onPressed: () => _studyWord(word['id']), child: Text("Study")),
        );
      },
    );
  }
}