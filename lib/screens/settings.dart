import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/spell_api_service.dart';
import 'ai_config_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Study settings state
  Map<String, dynamic>? userSettings;
  bool settingsLoading = false;
  String? settingsError;
  String studyWordsSource = 'CURRENT_TAG';
  int numStudyWords = 10;
  int spellRepeatCount = 3;
  String? loggedInUser;

  List<Map<String, String>> availableVoices = [];
  Map<String, String>? selectedVoice;
  static const String loggedInUserKey = 'loggedInUser';

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _loadLoggedInUser();
    await _loadVoices();
    await _loadUserSettings();
  }

  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString(loggedInUserKey);
    print('DEBUG SettingsPage _loadLoggedInUser: user=$user');
    setState(() => loggedInUser = user);
  }

  Future<void> _loadUserSettings() async {
    // Guest users don't need to load settings
    if (loggedInUser == null || loggedInUser == 'Guest') {
      print('DEBUG SettingsPage _loadUserSettings: skipping for guest user');
      return;
    }
    
    setState(() {
      settingsLoading = true;
      settingsError = null;
    });
    try {
      final profile = await SpellApiService.getUserProfile(loggedInUser!);
      print('DEBUG SettingsPage _loadUserSettings: profile=$profile');
      final userId = profile['id'] ?? null;
      if (userId == null) throw Exception('User ID not found');
      final settings = await SpellApiService.getUserSettings(userId);
      print('DEBUG SettingsPage _loadUserSettings: settings=$settings');
      setState(() {
        userSettings = settings;
        studyWordsSource = settings?['study_words_source'] ?? 'CURRENT_TAG';
        numStudyWords = settings?['num_study_words'] ?? 10;
        spellRepeatCount = settings?['spell_repeat_count'] ?? 3;
      });
    } catch (e) {
      print('DEBUG SettingsPage _loadUserSettings error: $e');
      setState(() {
        settingsError = 'Failed to load settings: $e';
      });
    } finally {
      setState(() {
        settingsLoading = false;
      });
    }
  }

  Future<void> _saveUserSettings() async {
    // Guest users don't need to save settings
    if (loggedInUser == null || loggedInUser == 'Guest') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login to save settings')));
      return;
    }
    
    setState(() {
      settingsLoading = true;
      settingsError = null;
    });
    try {
      final profile = await SpellApiService.getUserProfile(loggedInUser!);
      final userId = profile['id'] ?? null;
      if (userId == null) throw Exception('User ID not found');
      final updated = await SpellApiService.updateUserSettings(
        userId,
        studyWordsSource: studyWordsSource,
        numStudyWords: numStudyWords,
        spellRepeatCount: spellRepeatCount,
      );
      setState(() {
        userSettings = updated;
        studyWordsSource = updated['study_words_source'] ?? studyWordsSource;
        numStudyWords = updated['num_study_words'] ?? numStudyWords;
        spellRepeatCount = updated['spell_repeat_count'] ?? spellRepeatCount;
        settingsError = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      print('DEBUG SettingsPage _saveUserSettings error: $e');
      setState(() {
        settingsError = 'Failed to save settings: $e';
      });
    } finally {
      setState(() {
        settingsLoading = false;
      });
    }
  }

  Future<void> _loadVoices() async {
    try {
      final tts = FlutterTts();
      List<dynamic> voices = await tts.getVoices;
      setState(() {
        availableVoices = voices
            .whereType<Map>()
            .map((v) => Map<String, String>.from(v))
            .where((v) {
              final locale = v['locale'] ?? '';
              return locale == 'zh-CN' || locale == 'zh-TW' || locale == 'zh-HK';
            })
            .toList();
      });
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('selectedVoice');
      if (savedVoice != null) {
        final match = availableVoices.firstWhere(
          (v) => v['name'] == savedVoice,
          orElse: () => availableVoices.isNotEmpty ? availableVoices[0] : {},
        );
        setState(() {
          selectedVoice = match.isNotEmpty ? match : null;
        });
      }
    } catch (e) {
      // ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Welcome text
            if (loggedInUser != null && loggedInUser != 'Guest')
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Welcome, $loggedInUser!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              )
            else if (loggedInUser == 'Guest' || loggedInUser == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Welcome, Guest!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            // Study Settings Section (only for logged-in users)
            if (loggedInUser != null) ...[
              if (settingsLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (settingsError != null)
                  Text(settingsError!,
                      style: const TextStyle(color: Colors.red)),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Study Settings',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Source: '),
                            DropdownButton<String>(
                              value: studyWordsSource,
                              items: const [
                                DropdownMenuItem(
                                    value: 'ALL_TAGS',
                                    child: Text('All Tags')),
                                DropdownMenuItem(
                                    value: 'CURRENT_TAG',
                                    child: Text('Current Tag')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    studyWordsSource = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Number of Study Words: '),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: numStudyWords.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(),
                                onChanged: (val) {
                                  final n = int.tryParse(val);
                                  if (n != null && n > 0) {
                                    setState(() {
                                      numStudyWords = n;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Spell Repeat Count: '),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: spellRepeatCount.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(),
                                onChanged: (val) {
                                  final n = int.tryParse(val);
                                  if (n != null && n > 0) {
                                    setState(() {
                                      spellRepeatCount = n;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _saveUserSettings,
                          child: const Text('Save Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ] else ...[
              // Show message when not logged in
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Text('Please log in to customize settings'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Voice Selection Section
            if (availableVoices.isNotEmpty) ...[
              const Text("Chinese Voice Selection",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<Map<String, String>>(
                value: selectedVoice,
                isExpanded: true,
                hint: const Text("Select Chinese Voice"),
                items: availableVoices.map((voice) {
                  final name = voice['name'] ?? 'Unknown';
                  final locale = voice['locale'] ?? '';
                  return DropdownMenuItem(
                    value: voice,
                    child: Text('$name  [$locale]'),
                  );
                }).toList(),
                onChanged: (voice) async {
                  setState(() {
                    selectedVoice = voice;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selectedVoice', voice?['name'] ?? '');
                },
              ),
              const SizedBox(height: 24),
            ],
            // AI Configuration Button
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AIConfigPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.smart_toy,
                          color: Colors.blue[700], size: 32),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'AI Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}