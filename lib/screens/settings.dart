import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/spell_api_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'ai_config_page.dart';
import '../services/tts_web.dart' if (dart.library.io) '../services/tts_web_stub.dart';

class SettingsPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  
  const SettingsPage({Key? key, this.onLanguageChanged}) : super(key: key);

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
  String selectedLanguageCode = 'en';
  static const String loggedInUserKey = 'loggedInUser';
  
  // Browser voice selection (web only)
  List<Map<String, String>> browserVoices = [];
  String? selectedBrowserVoice;
  bool isGoogleCloudTTSAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _loadLoggedInUser();
    await _loadVoices();
    await _loadUserSettings();
    await _loadLanguage();
    if (kIsWeb) {
      await _checkGoogleCloudTTS();
      // Always load browser voices on web
      await _loadBrowserVoices();
    }
  }

  Future<void> _loadLanguage() async {
    final locale = await LanguageService.getSavedLanguage();
    setState(() {
      selectedLanguageCode = locale.languageCode;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    await LanguageService.saveLanguage(languageCode);
    setState(() {
      selectedLanguageCode = languageCode;
    });
    
    // Notify parent to change language
    if (widget.onLanguageChanged != null) {
      widget.onLanguageChanged!(Locale(languageCode));
    }
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageCode == 'en' 
              ? 'Language changed to English' 
              : '语言已更改为中文'),
        ),
      );
    }
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
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.pleaseLoginToSaveSettings ?? 'Please login to save settings')));
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
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.settingsSaved ?? 'Settings saved')));
    } catch (e) {
      print('DEBUG SettingsPage _saveUserSettings error: $e');
      setState(() {
        settingsError = '${AppLocalizations.of(context)?.failedToSaveSettings ?? "Failed to save settings"}: $e';
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

  Future<void> _loadBrowserVoices() async {
    if (!kIsWeb) return;
    
    try {
      // Wait a bit for voices to load in the browser
      await Future.delayed(const Duration(milliseconds: 500));
      var voices = getBrowserVoices();
      
      // If no voices yet, try again after a longer delay
      if (voices.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1500));
        voices = getBrowserVoices();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final savedVoiceName = prefs.getString('selectedBrowserVoice');
      
      setState(() {
        browserVoices = voices;
        if (savedVoiceName != null && savedVoiceName.isNotEmpty) {
          selectedBrowserVoice = savedVoiceName;
        }
      });
    } catch (e) {
      print('Error loading browser voices: $e');
    }
  }

  Future<void> _checkGoogleCloudTTS() async {
    if (!kIsWeb) return;
    
    try {
      // Try a simple test request to see if Google Cloud TTS is available
      final response = await SpellApiService.testGoogleCloudTTS();
      setState(() {
        isGoogleCloudTTSAvailable = response;
      });
    } catch (e) {
      print('Google Cloud TTS not available: $e');
      setState(() {
        isGoogleCloudTTSAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(localizations?.settings ?? "Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Language Selection Section (available for all users)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations?.language ?? 'Language',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(localizations?.selectLanguage ?? 'Select Language: '),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedLanguageCode,
                            isExpanded: true,
                            items: LanguageService.getSupportedLanguages()
                                .map((lang) => DropdownMenuItem<String>(
                                      value: lang['code'],
                                      child: Text(lang['name'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (languageCode) {
                              if (languageCode != null) {
                                _changeLanguage(languageCode);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Welcome text
            if (loggedInUser != null && loggedInUser != 'Guest')
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '${localizations?.welcome ?? "Welcome"}, $loggedInUser!',
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
                  '${localizations?.welcome ?? "Welcome"}, ${localizations?.guest ?? "Guest"}!',
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
                        Text(localizations?.studySettings ?? 'Study Settings',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('${localizations?.studyWordsSource ?? "Source"}: '),
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
                            Text('${localizations?.numStudyWords ?? "Number of Study Words"}: '),
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
                            Text('${localizations?.spellRepeatCount ?? "Spell Repeat Count"}: '),
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
                          child: Text(localizations?.saveSettings ?? 'Save Settings'),
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
                      Text(localizations?.pleaseLogInToCustomizeSettings ?? 'Please log in to customize settings'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        child: Text(localizations?.goToLogin ?? 'Go to Login'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Voice Selection Section - Always show
            if (kIsWeb && isGoogleCloudTTSAvailable) ...[
              // For web with Google Cloud TTS: Show Google Cloud TTS info
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud, color: Colors.blue[700], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            selectedLanguageCode == 'zh' ? "文字转语音" : "Text-to-Speech",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Google Cloud Text-to-Speech',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          selectedLanguageCode == 'zh' 
                            ? '使用高品质AI语音，自动识别语言。英文和中文语音针对最佳发音质量进行了优化。'
                            : 'Using high-quality AI voices with automatic language detection. English and Chinese voices are optimized for the best pronunciation quality.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Browser voice selection on web (always show)
            if (kIsWeb) ...[
              // For web: Show device/system voice selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.record_voice_over, color: Colors.orange[700], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            selectedLanguageCode == 'zh' ? "设备语音" : "Device Voice",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text(
                          selectedLanguageCode == 'zh' 
                            ? '使用您电脑上安装的系统语音。当Google云服务不可用时作为备选方案。'
                            : 'Uses the text-to-speech voices installed on your computer. Fallback option when Google Cloud TTS is not available.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (browserVoices.isEmpty) ...[
                        Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Text(selectedLanguageCode == 'zh' ? '正在加载语音...' : 'Loading voices...'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await _loadBrowserVoices();
                          },
                          child: Text(selectedLanguageCode == 'zh' ? '重新加载' : 'Reload'),
                        ),
                      ] else ...[
                        Text(
                          selectedLanguageCode == 'zh' ? '选择设备语音' : 'Select Device Voice',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: selectedBrowserVoice,
                          isExpanded: true,
                          hint: Text(selectedLanguageCode == 'zh' ? '选择语音' : 'Select Voice'),
                          items: browserVoices.map((voice) {
                            final name = voice['name'] ?? 'Unknown';
                            final lang = voice['lang'] ?? '';
                            return DropdownMenuItem(
                              value: name,
                              child: Text('$name ($lang)'),
                            );
                          }).toList(),
                          onChanged: (voiceName) async {
                            setState(() {
                              selectedBrowserVoice = voiceName;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('selectedBrowserVoice', voiceName ?? '');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else if (availableVoices.isNotEmpty) ...[
              // For native apps: Show voice selection dropdown
              Text(localizations?.chineseVoiceSelection ?? "Chinese Voice Selection",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<Map<String, String>>(
                value: selectedVoice,
                isExpanded: true,
                hint: Text(localizations?.selectChineseVoice ?? "Select Chinese Voice"),
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
            ],
            const SizedBox(height: 24),
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