import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';

class LeaderboardPage extends StatefulWidget {
  final String? currentUserName; // pass null if anonymous / not logged in
  const LeaderboardPage({super.key, this.currentUserName});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String? _selectedSchool;
  String? _selectedGrade;
  List<String> _schoolOptions = [];
  List<String> _gradeOptions = [];
  bool _loading = false;
  List<dynamic> _items = [];
  Map<String, dynamic>? _me;


  @override
  void initState() {
    super.initState();
    _initDropdowns();
    _fetchLeaderboard(auto: true);
  }

  Future<void> _initDropdowns() async {
    try {
      final schools = await SpellApiService.getLeaderboardSchools();
      String? userSchool;
      String? userGrade;
      // If logged in, fetch user profile for school/grade
      if (widget.currentUserName != null && widget.currentUserName!.isNotEmpty) {
        try {
          final profile = await SpellApiService.getUserProfile(widget.currentUserName!);
          userSchool = (profile['school'] != null && profile['school'].toString().isNotEmpty) ? profile['school'].toString() : null;
          userGrade = (profile['grade'] != null && profile['grade'].toString().isNotEmpty) ? profile['grade'].toString() : null;
        } catch (e) {
          // ignore profile fetch error
        }
      }
      setState(() {
        _schoolOptions = schools;
        // Only set if not empty/null and in options
        if (userSchool != null && schools.contains(userSchool)) {
          _selectedSchool = userSchool;
        }
      });
      // Update grade options after setting school
      await _updateGradeOptions();
      // Set grade if available and in options
      if (userGrade != null && _gradeOptions.contains(userGrade)) {
        setState(() {
          _selectedGrade = userGrade;
        });
      }
    } catch (e) {
      // ignore or show error
    }
  }

  Future<void> _updateGradeOptions() async {
    try {
      final grades = await SpellApiService.getLeaderboardGrades(school: _selectedSchool);
      setState(() {
        _gradeOptions = grades;
        // If the selected grade is not in the new list, clear it
        if (!_gradeOptions.contains(_selectedGrade)) {
          _selectedGrade = null;
        }
      });
    } catch (e) {
      // ignore or show error
    }
  }

  Future<void> _fetchLeaderboard({bool auto = false}) async {
    setState(() { _loading = true; });
    try {
      final school = _selectedSchool;
      final grade = _selectedGrade;
      final result = await SpellApiService.getLeaderboardTop(
        limit: 20,
        school: school,
        grade: grade,
        userNameHeader: widget.currentUserName,
      );
      setState(() {
        _items = (result['items'] ?? []) as List<dynamic>;
      });
      if (widget.currentUserName != null) {
        _me = await SpellApiService.getLeaderboardMe(
          limit: 20,
          school: school,
          grade: grade,
          userNameHeader: widget.currentUserName,
        );
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leaderboard: $e'))
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSchool,
                items: [DropdownMenuItem<String>(value: null, child: Text('All Schools'))]
                  + _schoolOptions.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                onChanged: (val) async {
                  setState(() {
                    _selectedSchool = val;
                  });
                  // Always retrieve grade list from backend and reset grade if not present
                  await _updateGradeOptions();
                },
                decoration: const InputDecoration(labelText: 'School'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGrade,
                items: [DropdownMenuItem<String>(value: null, child: Text('All Grades'))]
                  + _gradeOptions.map((g) => DropdownMenuItem<String>(value: g, child: Text(g))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedGrade = val;
                  });
                },
                decoration: const InputDecoration(labelText: 'Grade'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _fetchLeaderboard(auto: false),
              icon: const Icon(Icons.search),
              label: const Text('Apply'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(int index, Map item) {
    final rank = item['rank'] ?? (index + 1);
    final name = item['name'] ?? '';
    final points = item['total_points'] ?? 0;
    final school = item['school'];
    final grade = item['grade'];

    String? medal;
    if (rank == 1) medal = '🥇';
    else if (rank == 2) medal = '🥈';
    else if (rank == 3) medal = '🥉';

    final isMe = widget.currentUserName != null && widget.currentUserName == name;

    return Container(
      decoration: BoxDecoration(
        color: isMe ? Colors.yellow.withOpacity(0.2) : null,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(rank.toString()),
        ),
        title: Row(
          children: [
            if (medal != null) Text('$medal '),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        subtitle: (school != null || grade != null)
            ? Text([if (school != null && school.toString().isNotEmpty) school, if (grade != null && grade.toString().isNotEmpty) grade].join(' • '))
            : null,
        trailing: Text(points.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: RefreshIndicator(
        onRefresh: () => _fetchLeaderboard(auto: false),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            if (_me != null && _me!['name'] != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('Your Rank: ${_me!['rank'] ?? '—'}'),
                  subtitle: Text('Points: ${_me!['total_points'] ?? 0}'),
                ),
              ),
            if (_loading) const LinearProgressIndicator(),
            if (_items.isEmpty && !_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No leaderboard data yet.')),
              ),
            ..._items.asMap().entries.map((e) => _buildRow(e.key, e.value as Map)).toList(),
          ],
        ),
      ),
    );
  }
}
