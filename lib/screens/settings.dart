import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/spell_api_service.dart';
import 'ai_config_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(String userName) onLogin;

  const SettingsPage({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> handleChangePassword() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Required'),
          content: const Text('Please enter and confirm your new password.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Mismatch'),
          content: const Text('The new passwords do not match. Please try again.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
        ),
      );
      return;
    }
    try {
      final data = {"password": newPassword};
      await SpellApiService.updateUserProfile(name, data);
      setState(() => message = "Password changed successfully!");
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } catch (e) {
      setState(() => message = "Failed to change password.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password.')),
      );
    }
  }
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // User settings state
  Map<String, dynamic>? userSettings;
  bool settingsLoading = false;
  String? settingsError;
  String studyWordsSource = 'ALL_TAGS';
  int numStudyWords = 10;
  int spellRepeatCount = 1;

  Future<void> _loadUserSettings() async {
    if (loggedInUser == null) return;
    setState(() { settingsLoading = true; settingsError = null; });
    try {
      // Assume userName == userId for now (if not, adjust accordingly)
      final profile = await SpellApiService.getUserProfile(loggedInUser!);
      final userId = profile['id'] ?? null;
      if (userId == null) throw Exception('User ID not found');
      final settings = await SpellApiService.getUserSettings(userId);
      setState(() {
        userSettings = settings;
        studyWordsSource = settings?['study_words_source'] ?? 'ALL_TAGS';
        numStudyWords = settings?['num_study_words'] ?? 10;
        spellRepeatCount = settings?['spell_repeat_count'] ?? 1;
      });
    } catch (e) {
      setState(() { settingsError = 'Failed to load settings'; });
    } finally {
      setState(() { settingsLoading = false; });
    }
  }

  Future<void> _saveUserSettings() async {
    if (loggedInUser == null) return;
    setState(() { settingsLoading = true; settingsError = null; });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      setState(() { settingsError = 'Failed to save settings'; });
    } finally {
      setState(() { settingsLoading = false; });
    }
  }
  List<Map<String, String>> availableVoices = [];
  Map<String, String>? selectedVoice;
  static const String loggedInUserKey = 'loggedInUser';
  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      // Use FlutterTts to get voices
      // Import here to avoid issues on web
      // ignore: import_deferred_library
      final tts = await (await importTts());
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

  Future<dynamic> importTts() async {
    // Just return FlutterTts instance
    return FlutterTts();
  }

  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString(loggedInUserKey);
    if (savedUser != null && savedUser.isNotEmpty) {
      try {
        final profile = await SpellApiService.getUserProfile(savedUser);
        setState(() {
          isExistingUser = true;
          loggedInUser = savedUser;
          _nameController.text = savedUser;
          _ageController.text = profile["age"]?.toString() ?? "";
          _emailController.text = profile["email"] ?? "";
          _phoneController.text = profile["phone"] ?? "";
          _schoolController.text = profile["school"] ?? "";
          _gradeController.text = profile["grade"] ?? "";
          message = "Welcome back, $savedUser!";
        });
        await _loadUserSettings();
      } catch (e) {
        // If profile fetch fails, clear saved user
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(loggedInUserKey);
      }
    }
  }
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  bool isExistingUser = false;
  String message = '';
  String? loggedInUser;

  Future<void> handleLoginOrRegister() async {
    final nameRaw = _nameController.text.trim();
    final passwordRaw = _passwordController.text;
    if (nameRaw.isEmpty) {
      setState(() => message = "Name cannot be empty.");
      return;
    }
    final name = nameRaw.toUpperCase();
    _nameController.text = name;

    try {
      // Check if user exists
      Map<String, dynamic> profile = {};
      bool userExists = false;
      try {
        profile = await SpellApiService.getUserProfile(name);
        userExists = profile.isNotEmpty;
      } catch (_) {
        userExists = false;
      }
      if (userExists) {
        // Existing user: verify password
        final isValid = await SpellApiService.verifyUserPassword(name, passwordRaw);
        if (!isValid) {
          setState(() {
            isExistingUser = false;
            loggedInUser = null;
            message = "Incorrect password. Please try again.";
          });
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(loggedInUserKey, name);
        setState(() {
          isExistingUser = true;
          loggedInUser = name;
          _ageController.text = profile["age"]?.toString() ?? "";
          _emailController.text = profile["email"] ?? "";
          _phoneController.text = profile["phone"] ?? "";
          _schoolController.text = profile["school"] ?? "";
          _gradeController.text = profile["grade"] ?? "";
          message = "Welcome back, $name!";
        });
        widget.onLogin(name);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop('login-success');
        }
      } else {
        // New user: ask to confirm password
        final confirm = await showDialog<String>(
          context: context,
          builder: (context) {
            final TextEditingController _confirmController = TextEditingController();
            return AlertDialog(
              title: const Text('Set Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please confirm your password:'),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_confirmController.text),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        if (confirm == null || confirm != passwordRaw) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match. Please try again.')),
          );
          return;
        }
        // Create user with password
        final data = {"name": name, "password": passwordRaw};
        await SpellApiService.createUserProfile(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(loggedInUserKey, name);
        setState(() {
          isExistingUser = true;
          loggedInUser = name;
          _ageController.clear();
          _emailController.clear();
          _phoneController.clear();
          _schoolController.clear();
          _gradeController.clear();
          message = "Welcome, $name! Please complete your profile.";
        });
        widget.onLogin(name);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. Please complete your profile.')),
        );
      }
    } catch (e) {
      setState(() {
        isExistingUser = false;
        loggedInUser = null;
        message = "New user. Please fill in your profile to register.";
        _nameController.text = name;
      });
    }
  }

  Future<void> handleProfileUpdate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final data = {
      "name": name,
      "age": int.tryParse(_ageController.text),
      "email": _emailController.text,
      "phone": _phoneController.text,
      "school": _schoolController.text,
      "grade": _gradeController.text,
    };

    // If user is changing password, require confirmation
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword != confirmPassword) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Mismatch'),
            content: const Text('The new passwords do not match. Please try again.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
      // Ask user to re-enter password for confirmation
      final confirmed = await showDialog<String>(
        context: context,
        builder: (context) {
          final TextEditingController _reenterController = TextEditingController();
          return AlertDialog(
            title: const Text('Confirm Password Change'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please enter your new password again to confirm:'),
                TextField(
                  controller: _reenterController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_reenterController.text),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      if (confirmed == null || confirmed != newPassword) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Not Changed'),
            content: const Text('Password change cancelled or did not match.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
        return;
      }
      data["password"] = newPassword;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (isExistingUser) {
        await SpellApiService.updateUserProfile(name, data);
        setState(() => message = "Profile updated successfully!");
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        await SpellApiService.createUserProfile(data);
        await prefs.setString(loggedInUserKey, name);
        setState(() {
          isExistingUser = true;
          loggedInUser = name;
          message = "Profile created successfully!";
        });
        widget.onLogin(name);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
      }
    } catch (e) {
      setState(() => message = "Failed to update profile.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  void handleLogout() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(loggedInUserKey);
      prefs.remove('selectedVoice');
      setState(() {
        loggedInUser = null;
        isExistingUser = false;
        userSettings = null;
        settingsError = null;
  settingsLoading = false;
  studyWordsSource = 'ALL_TAGS';
  numStudyWords = 10;
  spellRepeatCount = 1;
        _nameController.clear();
        _ageController.clear();
        _emailController.clear();
        _phoneController.clear();
        _schoolController.clear();
        _gradeController.clear();
        message = "Logged out.";
      });
      // Pop and notify parent for logout
      Navigator.of(context).pop('logout');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (loggedInUser == null) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: handleLoginOrRegister,
                  child: const Text("Login / Register"),
                ),
                const SizedBox(height: 20),
                if (isExistingUser || message.contains("New user"))
                  Column(
                    children: [
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: "Age"),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: "Phone"),
                      ),
                      TextFormField(
                        controller: _schoolController,
                        decoration: const InputDecoration(labelText: "School"),
                      ),
                      TextFormField(
                        controller: _gradeController,
                        decoration: const InputDecoration(labelText: "Grade"),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: handleProfileUpdate,
                        child: const Text("Save Profile"),
                      ),
                    ],
                  ),
              ] else ...[
                Text(
                  "Welcome back, $loggedInUser",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                // Password change section
                const SizedBox(height: 10),
                Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: "New Password"),
                  obscureText: true,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: "Confirm New Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: handleChangePassword,
                  child: const Text("Change Password"),
                ),
                const Divider(height: 32),
                // Profile update section
                Text("Update Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: "Age"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                TextFormField(
                  controller: _schoolController,
                  decoration: const InputDecoration(labelText: "School"),
                ),
                TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(labelText: "Grade"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: handleProfileUpdate,
                  child: const Text("Save Profile"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: handleLogout,
                  child: const Text("Logout"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
                // User settings UI
                const SizedBox(height: 24),
                if (settingsLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (settingsError != null)
                    Text(settingsError!, style: const TextStyle(color: Colors.red)),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Study Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Source: '),
                              DropdownButton<String>(
                                value: studyWordsSource,
                                items: const [
                                  DropdownMenuItem(value: 'ALL_TAGS', child: Text('All Tags')),
                                  DropdownMenuItem(value: 'CURRENT_TAG', child: Text('Current Tag')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() { studyWordsSource = val; });
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
                                    if (n != null && n > 0) setState(() { numStudyWords = n; });
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
                                    if (n != null && n > 0) setState(() { spellRepeatCount = n; });
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
              ],
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.blueAccent),
              ),
              if (availableVoices.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text("Chinese Voice Selection", style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16),
              ],
              // ===================== AI CONFIGURATION BUTTON =====================
              const SizedBox(height: 20),
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
                        Icon(Icons.smart_toy, color: Colors.blue[700], size: 32),
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
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}