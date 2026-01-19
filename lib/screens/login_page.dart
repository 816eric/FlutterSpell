import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/spell_api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;
  final FocusNode _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() { _loading = true; _error = ''; });
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || password.isEmpty) {
      setState(() { _error = 'Please enter both user name and password.'; _loading = false; });
      return;
    }
    try {
      final isValid = await SpellApiService.verifyUserPassword(name, password);
      if (isValid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggedInUser', name);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() { _error = 'Incorrect user name or password.'; });
      }
    } catch (e) {
      setState(() { _error = 'Login failed.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _handleGuestLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUser', 'Guest');
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _handleRegister({
    String? initialDialogError,
    String? previousName,
    String? previousPassword,
    String? previousConfirmPassword,
    String? previousGrade,
  }) async {
    setState(() { _loading = true; _error = ''; });
    final TextEditingController _registerNameController = TextEditingController(text: previousName ?? _nameController.text);
    final TextEditingController _registerPasswordController = TextEditingController(text: previousPassword ?? _passwordController.text);
    final TextEditingController _registerConfirmController = TextEditingController(text: previousConfirmPassword ?? '');
    String? _selectedGrade = previousGrade;
    String? dialogError = initialDialogError;
    FocusNode _dialogNameFocus = FocusNode();
    
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final gradeOptions = [
              'N1', 'N2', 'K1', 'K2',
              ...List.generate(6, (i) => 'P${i + 1}'),
              ...List.generate(6, (i) => 'S${i + 1}')
            ];
            // Auto-focus name field if there's an error
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (initialDialogError != null && _dialogNameFocus.canRequestFocus) {
                _dialogNameFocus.requestFocus();
              }
            });
            return AlertDialog(
              title: const Text('Register'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _registerNameController,
                    focusNode: _dialogNameFocus,
                    decoration: const InputDecoration(labelText: 'User Name *'),
                  ),
                  TextField(
                    controller: _registerPasswordController,
                    decoration: const InputDecoration(labelText: 'Password *'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: _registerConfirmController,
                    decoration: const InputDecoration(labelText: 'Confirm Password *'),
                    obscureText: true,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(labelText: 'Grade *'),
                    items: gradeOptions.map((grade) => DropdownMenuItem(
                      value: grade,
                      child: Text(grade),
                    )).toList(),
                    onChanged: (value) {
                      setState(() { _selectedGrade = value; });
                    },
                  ),
                  if (dialogError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final regName = _registerNameController.text.trim();
                    final regPassword = _registerPasswordController.text;
                    final regConfirm = _registerConfirmController.text;
                    final regGrade = _selectedGrade;
                    if (regName.isEmpty || regPassword.isEmpty || regConfirm.isEmpty || regGrade == null || regGrade.isEmpty) {
                      setState(() { dialogError = 'All fields are required.'; });
                      return;
                    }
                    if (regPassword != regConfirm) {
                      setState(() { dialogError = 'Passwords do not match.'; });
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Register'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirm != true) {
      setState(() { _loading = false; });
      _dialogNameFocus.dispose();
      return;
    }
    final regName = _registerNameController.text.trim();
    final regPassword = _registerPasswordController.text;
    final regConfirm = _registerConfirmController.text;
    final regGrade = _selectedGrade ?? '';
    try {
      final data = {"name": regName, "password": regPassword, "grade": regGrade};
      await SpellApiService.createUserProfile(data);
      
      // Save user as logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUser', regName);
      
      // Try to assign tags containing the grade to the user (non-blocking)
      try {
        final allTags = await SpellApiService.getAllTags();
        final matchingTags = allTags.where((tag) {
          final tagName = (tag['name'] ?? tag['tag'] ?? '').toString();
          return tagName.contains(regGrade);
        }).map((tag) => tag['id']).where((id) => id != null).cast<int>().toList();
        if (matchingTags.isNotEmpty) {
          await SpellApiService.assignTagsToUser(regName, matchingTags);
        }
      } catch (tagError) {
        // If tag assignment fails, just log it but continue with registration
        print('WARNING: Failed to assign default tags: $tagError');
      }
      
      // Navigate to tag assignment page for new user to select their classes
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e, st) {
      print('Registration failed:');
      print(e);
      print(st);
      
      // Check if user already exists
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already exists') || errorMsg.contains('user already')) {
        // Re-open the dialog with error message and keep all form data
        setState(() { _loading = false; });
        _dialogNameFocus.dispose();
        // Re-show the dialog with the error and preserve form data
        _handleRegister(
          initialDialogError: 'Username already exists. Please choose a different username.',
          previousName: regName,
          previousPassword: regPassword,
          previousConfirmPassword: regConfirm,
          previousGrade: regGrade,
        );
      } else {
        setState(() { 
          _error = 'Registration failed: ' + e.toString();
          _loading = false;
        });
        _dialogNameFocus.dispose();
      }
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  decoration: const InputDecoration(labelText: 'User Name'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _handleLogin,
                        child: const Text('Login'),
                      ),
                      ElevatedButton(
                        onPressed: _handleGuestLogin,
                        child: const Text('Login as Guest'),
                      ),
                      ElevatedButton(
                        onPressed: _handleRegister,
                        child: const Text('Register'),
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
