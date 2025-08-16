import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/spell_api_service.dart';

class SettingsPage extends StatefulWidget {
  final Function(String userName) onLogin;

  const SettingsPage({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
        availableVoices = voices.whereType<Map>().map((v) => Map<String, String>.from(v)).toList();
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
      } catch (e) {
        // If profile fetch fails, clear saved user
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(loggedInUserKey);
      }
    }
  }
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
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
    if (nameRaw.isEmpty) {
      setState(() => message = "Name cannot be empty.");
      return;
    }
    final name = nameRaw.toUpperCase();
    _nameController.text = name;

    try {
      final profile = await SpellApiService.getUserProfile(name);
      if (profile.isNotEmpty) {
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
        // Call onLogin after setState to update parent immediately
        widget.onLogin(name);
        // If we were navigated from tag assignment, pop back to it
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop('login-success');
        }
        // Do NOT pop the page after login otherwise
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

    try {
      final prefs = await SharedPreferences.getInstance();
      if (isExistingUser) {
        await SpellApiService.updateUserProfile(name, data);
        setState(() => message = "Profile updated successfully!");
      } else {
        await SpellApiService.createUserProfile(data);
        await prefs.setString(loggedInUserKey, name);
        setState(() {
          isExistingUser = true;
          loggedInUser = name;
          message = "Profile created successfully!";
        });
        // Call onLogin after setState to update parent immediately
        widget.onLogin(name);
        // Do NOT pop the page after registration
      }
    } catch (e) {
      setState(() => message = "Failed to update profile.");
    }

  }

  void handleLogout() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(loggedInUserKey);
      prefs.remove('selectedVoice');
      setState(() {
        loggedInUser = null;
        isExistingUser = false;
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
                Text("Logged in as: $loggedInUser", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
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
                // ...existing code...
              ],
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.blueAccent),
              ),
              if (availableVoices.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text("TTS Voice Selection", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<Map<String, String>>(
                  value: selectedVoice,
                  isExpanded: true,
                  hint: const Text("Select TTS Voice"),
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
            ],
          ),
        ),
      ),
    );
  }
}