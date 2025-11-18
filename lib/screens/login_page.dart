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

  Future<void> _handleRegister() async {
    setState(() { _loading = true; _error = ''; });
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || password.isEmpty) {
      setState(() { _error = 'Please enter both user name and password.'; _loading = false; });
      return;
    }
    final confirm = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController _confirmController = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm Password'),
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
    if (confirm == null || confirm != password) {
      setState(() { _error = 'Passwords do not match.'; _loading = false; });
      return;
    }
    try {
      final data = {"name": name, "password": password};
      await SpellApiService.createUserProfile(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUser', name);
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() { _error = 'Registration failed.'; });
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
