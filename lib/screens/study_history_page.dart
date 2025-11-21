import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';

class StudyHistoryPage extends StatefulWidget {
  final String userName;
  const StudyHistoryPage({super.key, required this.userName});

  @override
  State<StudyHistoryPage> createState() => _StudyHistoryPageState();
}

class _StudyHistoryPageState extends State<StudyHistoryPage> {
  bool _loading = true;
  List<dynamic> _allHistory = [];
  List<dynamic> _filteredHistory = [];
  String _selectedFilter = 'All';
  String _selectedType = 'All'; // All, Study, Quiz
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; });
    try {
      final studyHistory = await SpellApiService.getStudyHistory(widget.userName, limit: 1000);
      final quizHistory = await SpellApiService.getQuizHistory(widget.userName, limit: 1000);
      
      // Mark each record with its type
      final studyRecords = studyHistory.map((r) => {...r, 'type': 'study'}).toList();
      final quizRecords = quizHistory.map((r) => {...r, 'type': 'quiz'}).toList();
      
      // Combine and sort by date (newest first)
      final combined = [...studyRecords, ...quizRecords];
      combined.sort((a, b) {
        final dateA = DateTime.parse(a['studied_at'] ?? a['completed_at']);
        final dateB = DateTime.parse(b['studied_at'] ?? b['completed_at']);
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _allHistory = combined;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
      setState(() { _loading = false; });
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    
    // First filter by type
    var filtered = _allHistory;
    if (_selectedType == 'Study') {
      filtered = _allHistory.where((r) => r['type'] == 'study').toList();
    } else if (_selectedType == 'Quiz') {
      filtered = _allHistory.where((r) => r['type'] == 'quiz').toList();
    }
    
    // Then filter by date
    switch (_selectedFilter) {
      case 'Weekly':
        final weekAgo = now.subtract(const Duration(days: 7));
        _filteredHistory = filtered.where((record) {
          final date = DateTime.parse(record['studied_at'] ?? record['completed_at']);
          return date.isAfter(weekAgo);
        }).toList();
        break;
      case 'Monthly':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        _filteredHistory = filtered.where((record) {
          final date = DateTime.parse(record['studied_at'] ?? record['completed_at']);
          return date.isAfter(monthAgo);
        }).toList();
        break;
      case 'Quarterly':
        final quarterAgo = DateTime(now.year, now.month - 3, now.day);
        _filteredHistory = filtered.where((record) {
          final date = DateTime.parse(record['studied_at'] ?? record['completed_at']);
          return date.isAfter(quarterAgo);
        }).toList();
        break;
      case 'Yearly':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        _filteredHistory = filtered.where((record) {
          final date = DateTime.parse(record['studied_at'] ?? record['completed_at']);
          return date.isAfter(yearAgo);
        }).toList();
        break;
      default: // 'All'
        _filteredHistory = filtered;
    }
    _currentPage = 0; // Reset to first page when filter changes
  }

  void _onFilterChanged(String? newFilter) {
    if (newFilter == null) return;
    setState(() {
      _selectedFilter = newFilter;
      _applyFilter();
    });
  }

  List<dynamic> get _currentPageData {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredHistory.length);
    return _filteredHistory.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredHistory.length / _itemsPerPage).ceil();

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() { _currentPage++; });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() { _currentPage--; });
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 0: return 'Again';
      case 1: return 'Hard';
      case 3: return 'Good';
      case 5: return 'Easy';
      default: return 'Unknown';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 0: return Colors.red;
      case 1: return Colors.orange;
      case 3: return Colors.blue;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete ALL study and quiz history?\n\n'
          'This action cannot be undone and all your records will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Future.wait([
        SpellApiService.clearStudyHistory(widget.userName),
        SpellApiService.clearQuizHistory(widget.userName),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history cleared successfully')),
      );
      _loadHistory(); // Reload to show empty state
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear history: $e')),
      );
    }
  }

  Widget _buildStats() {
    if (_filteredHistory.isEmpty) return const SizedBox.shrink();

    final studyRecords = _filteredHistory.where((r) => r['type'] == 'study').toList();
    final quizRecords = _filteredHistory.where((r) => r['type'] == 'quiz').toList();
    
    final totalStudied = studyRecords.length;
    final totalQuiz = quizRecords.length;
    final againCount = studyRecords.where((r) => r['difficulty'] == 0).length;
    final hardCount = studyRecords.where((r) => r['difficulty'] == 1).length;
    final goodCount = studyRecords.where((r) => r['difficulty'] == 3).length;
    final easyCount = studyRecords.where((r) => r['difficulty'] == 5).length;
    final correctCount = quizRecords.where((r) => r['is_correct'] == true).length;
    final incorrectCount = quizRecords.where((r) => r['is_correct'] == false).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics ($_selectedFilter)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (totalStudied > 0) ...[
            const Text('Study Records:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalStudied.toString(), Colors.blue),
                _buildStatItem('Again', againCount.toString(), Colors.red),
                _buildStatItem('Hard', hardCount.toString(), Colors.orange),
                _buildStatItem('Good', goodCount.toString(), Colors.blue),
                _buildStatItem('Easy', easyCount.toString(), Colors.green),
              ],
            ),
          ],
          if (totalQuiz > 0) ...[
            const SizedBox(height: 16),
            const Text('Quiz Records:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalQuiz.toString(), Colors.purple),
                _buildStatItem('Correct', correctCount.toString(), Colors.green),
                _buildStatItem('Incorrect', incorrectCount.toString(), Colors.red),
                _buildStatItem('Accuracy', totalQuiz > 0 ? '${(correctCount / totalQuiz * 100).toStringAsFixed(0)}%' : '0%', Colors.blue),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning History'),
        actions: [
          if (_allHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear All History',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No study history yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete some study sessions to see your history here',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Type filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Type: ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: ['All', 'Study', 'Quiz']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (newType) {
                                if (newType == null) return;
                                setState(() {
                                  _selectedType = newType;
                                  _applyFilter();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time period filter
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Period: ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedFilter,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: ['All', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']
                                  .map((filter) => DropdownMenuItem(
                                        value: filter,
                                        child: Text(filter),
                                      ))
                                  .toList(),
                              onChanged: _onFilterChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Statistics
                    _buildStats(),
                    // History list
                    Expanded(
                      child: _filteredHistory.isEmpty
                          ? Center(
                              child: Text(
                                'No records found for $_selectedFilter period',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _currentPageData.length,
                              itemBuilder: (context, index) {
                                final record = _currentPageData[index];
                                final isStudy = record['type'] == 'study';
                                final date = DateTime.parse(record['studied_at'] ?? record['completed_at']);

                                if (isStudy) {
                                  final difficulty = record['difficulty'] as int;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getDifficultyColor(difficulty),
                                        child: const Icon(Icons.book, color: Colors.white),
                                      ),
                                      title: Text(
                                        record['word'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Study • ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          _getDifficultyText(difficulty),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        backgroundColor: _getDifficultyColor(difficulty),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Quiz record
                                  final isCorrect = record['is_correct'] as bool;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isCorrect ? Colors.green : Colors.red,
                                        child: Icon(
                                          isCorrect ? Icons.check : Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        record['word'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Quiz • ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          isCorrect ? 'Correct' : 'Incorrect',
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        backgroundColor: isCorrect ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                    // Pagination controls
                    if (_filteredHistory.isNotEmpty && _totalPages > 1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _currentPage > 0 ? _previousPage : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Previous'),
                            ),
                            Text(
                              'Page ${_currentPage + 1} of $_totalPages',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            ElevatedButton.icon(
                              onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Next'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
