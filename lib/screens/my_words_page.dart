import 'dart:io';
// import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:tesseract_ocr/tesseract_ocr.dart';
// import 'package:tesseract_ocr/tesseract_ocr.dart';
import '../services/spell_api_service.dart';
import '../services/ai_service.dart';
// import 'tag_manager.dart';
import 'tag_assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyWordsPage extends StatefulWidget {
  final String userName;
  const MyWordsPage({super.key, required this.userName});

  @override
  State<MyWordsPage> createState() => _MyWordsPageState();
}

class _MyWordsPageState extends State<MyWordsPage> {
  // int _selectedPage = 0;

  final List<String> _pages = [
    "Add My Words",
    "Manage Exist Words/Classes"
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
              // setState(() => _selectedPage = index); // removed unused _selectedPage
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
      String extractedText = "";
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Extracting words from image...')),
            ],
          ),
        ),
      );
      
      if (kIsWeb) {
        // Web: Use AI Service for word extraction
        try {
          final aiService = AIService();
          final words = await aiService.extractWordsFromImage(pickedFile);
          print('[MyWordsPage] Extracted words: $words');
          extractedText = words.join(', ');
          print('[MyWordsPage] Joined text: $extractedText');
        } catch (e) {
          print('[MyWordsPage] Error extracting words: $e');
          if (e.toString().contains('API key is not configured')) {
            extractedText = "[Please configure AI settings first. Go to Settings > AI Configuration]";
          } else {
            extractedText = "[Failed to extract text: $e]";
          }
        }
      } else if (Platform.isAndroid) {
        // Android: Try AI Service first, fallback to google_ml_kit
        try {
          final aiService = AIService();
          final apiKey = await aiService.getAiApiKey();
          
          if (apiKey.isNotEmpty) {
            // Use AI Service if configured
            final words = await aiService.extractWordsFromImage(pickedFile);
            print('[MyWordsPage] Extracted words: $words');
            extractedText = words.join(', ');
          } else {
            // Fallback to google_ml_kit
            _imageFile = File(pickedFile.path);
            final inputImage = InputImage.fromFile(_imageFile!);
            final textRecognizer = GoogleMlKit.vision.textRecognizer();
            final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
            extractedText = recognizedText.text.trim();
            await textRecognizer.close();
          }
        } catch (e) {
          print('[MyWordsPage] Error extracting words: $e');
          if (e.toString().contains('API key is not configured')) {
            extractedText = "[Please configure AI settings first. Go to Settings > AI Configuration]";
          } else {
            extractedText = "[Failed to extract text: $e]";
          }
        }
      } else {
        extractedText = "[OCR not supported on this platform]";
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
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
                  _tagController.text = "SJIJ::Px::CN/EN::Termx";
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
    final input = _wordController.text.trim();
    final lang = _selectedLanguage;
    final tag = _tagController.text.trim();

    if (input.isEmpty || lang.isEmpty) return;

    // Split input by newlines or commas
    final entries = input.split(RegExp(r'[\n,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    int successCount = 0;
    for (final word in entries) {
      final wordData = {
        "text": word,
        "language": lang
      };
      try {
        await SpellApiService.createUserWord(widget.userName, wordData, tag: tag.isNotEmpty ? tag : null);
        successCount++;
      } catch (e) {
        // Optionally handle errors for individual words
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added $successCount word(s)/sentence(s)")),
    );
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
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              final cursorPos = _tagController.selection.start;
              _tagController.value = TextEditingValue(
                text: value.toUpperCase(),
                selection: TextSelection.collapsed(offset: cursorPos),
              );
            },
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