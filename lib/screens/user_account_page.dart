import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/spell_api_service.dart';
import 'login_page.dart';

class UserAccountPage extends StatefulWidget {
  final String userName;

  const UserAccountPage({Key? key, required this.userName}) : super(key: key);

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _message = '';
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SpellApiService.getUserProfile(widget.userName);
      setState(() {
        _userProfile = profile;
        _nameController.text = profile['name'] ?? '';
        _ageController.text = profile['age']?.toString() ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _schoolController.text = profile['school'] ?? '';
        _gradeController.text = profile['grade'] ?? '';
      });
    } catch (e) {
      setState(() => _message = 'Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _message = 'Username cannot be empty');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'age': _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'school': _schoolController.text.isEmpty ? null : _schoolController.text,
        'grade': _gradeController.text.isEmpty ? null : _gradeController.text,
      };

      await SpellApiService.updateUserProfile(widget.userName, data);
      setState(() => _message = 'Profile updated successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _message = 'Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _message = 'Please enter and confirm your new password');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _message = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {'password': newPassword};
      await SpellApiService.updateUserProfile(widget.userName, data);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _message = 'Password changed successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _message = 'Failed to change password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('loggedInUser');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (widget.userName.isEmpty || widget.userName == 'Guest') {
      return Scaffold(
        appBar: AppBar(title: const Text('User Account')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view your account', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Account')),
      body: _isLoading && _userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('User Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _schoolController,
                            decoration: const InputDecoration(
                              labelText: 'School',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _gradeController,
                            decoration: const InputDecoration(
                              labelText: 'Grade',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              child: const Text('Save Profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Change Password Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              child: const Text('Change Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // Message Display
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _message.contains('successfully') ? Colors.green[100] : Colors.red[100],
                          border: Border.all(color: _message.contains('successfully') ? Colors.green : Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message,
                          style: TextStyle(
                            color: _message.contains('successfully') ? Colors.green[800] : Colors.red[800],
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
