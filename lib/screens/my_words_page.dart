import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/spell_api_service.dart';
import 'tag_manager.dart';
import 'tag_assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyWordsPage extends StatefulWidget {
  final String userName;
  const MyWordsPage({super.key, required this.userName});

  @override
  State<MyWordsPage> createState() => _MyWordsPageState();
}

class _MyWordsPageState extends State<MyWordsPage> {
  int _selectedPage = 0;

  final List<String> _pages = [
    "Add My Words",
    "Tag Assignment"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Words"),
      ),
      body: ListView(
        children: List.generate(_pages.length, (index) {
          return ListTile(
            title: Text(_pages[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              setState(() => _selectedPage = index);
              // Always get the latest userName from SharedPreferences before navigating
              final prefs = await SharedPreferences.getInstance();
              final savedUser = prefs.getString('loggedInUser');
              final latestUserName = (savedUser != null && savedUser.isNotEmpty && savedUser != 'Guest') ? savedUser : 'Guest';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    if (index == 0) return AddMyWordsPage(userName: latestUserName);
                    // Only Tag Assignment remains as second page
                    return TagAssignmentPage(userName: latestUserName);
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class AddMyWordsPage extends StatefulWidget {
  final String userName;
  const AddMyWordsPage({super.key, required this.userName});

  @override
  State<AddMyWordsPage> createState() => _AddMyWordsPageState();
}

class _AddMyWordsPageState extends State<AddMyWordsPage> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  String _selectedLanguage = 'en';
  File? _imageFile;

  final List<String> languages = ['en', 'zh', 'other'];

  Future<void> pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      // Simulated OCR result
      String extractedText = "[extracted text from image]";
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Edit OCR Result"),
          content: TextField(
            controller: TextEditingController(text: extractedText),
            maxLines: 4,
            onChanged: (value) => extractedText = value,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _wordController.text = extractedText;
                  _tagController.text = "photo_imported";
                });
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  Future<void> submitWord() async {
    final word = _wordController.text.trim();
    final lang = _selectedLanguage;
    final tag = _tagController.text.trim();

    if (word.isEmpty || lang.isEmpty) return;

    // Prepare word data without tag
    final wordData = {
      "text": word,
      "language": lang
    };

    // Pass tag as query parameter if not empty
    await SpellApiService.createUserWord(widget.userName, wordData, tag: tag.isNotEmpty ? tag : null);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Word submitted")));
    _wordController.clear();
    _tagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add My Words")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _wordController,
            decoration: const InputDecoration(labelText: "Word or Sentence"),
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            items: languages.map((lang) {
              return DropdownMenuItem(value: lang, child: Text(lang.toUpperCase()));
            }).toList(),
            onChanged: (value) => setState(() => _selectedLanguage = value!),
          ),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(labelText: "Suggested Tag (editable)"),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => pickImage(fromCamera: false),
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => pickImage(fromCamera: true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Photo"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: submitWord,
            child: const Text("Submit Word"),
          ),
        ],
      ),
    );
  }
}