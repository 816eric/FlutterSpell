import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';
import '../services/ai_service.dart';

class StudySuggestionPage extends StatefulWidget {
  final String userName;
  const StudySuggestionPage({super.key, required this.userName});

  @override
  State<StudySuggestionPage> createState() => _StudySuggestionPageState();
}

class _StudySuggestionPageState extends State<StudySuggestionPage> {
  bool _loading = true;
  bool _analyzing = false;
  String _selectedPeriod = 'Weekly';
  List<dynamic> _combinedHistory = [];
  List<dynamic> _filtered = [];
  String? _aiResult;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; });
    try {
      final study = await SpellApiService.getStudyHistory(widget.userName, limit: 2000);
      final quiz = await SpellApiService.getQuizHistory(widget.userName, limit: 2000);

      final studyRecords = study.map((r) => {...r, 'type': 'study'}).toList();
      final quizRecords = quiz.map((r) => {...r, 'type': 'quiz'}).toList();

      final combined = [...studyRecords, ...quizRecords];
      combined.sort((a, b) {
        final da = DateTime.parse(a['studied_at'] ?? a['completed_at']);
        final db = DateTime.parse(b['studied_at'] ?? b['completed_at']);
        return db.compareTo(da);
      });

      setState(() {
        _combinedHistory = combined;
        _applyPeriodFilter();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }

  void _applyPeriodFilter() {
    final now = DateTime.now();
    DateTime from;
    switch (_selectedPeriod) {
      case 'Weekly':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
        from = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Quarterly':
        from = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Yearly':
        from = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        from = DateTime(1970);
    }
    _filtered = _combinedHistory.where((r) {
      final d = DateTime.parse(r['studied_at'] ?? r['completed_at']);
      return d.isAfter(from);
    }).toList();
  }

  Map<String, dynamic> _buildAggregates(List<dynamic> records) {
    final study = records.where((r) => r['type'] == 'study');
    final quiz = records.where((r) => r['type'] == 'quiz');

    final difficultyCounts = <String, int>{'again':0,'hard':0,'good':0,'easy':0};
    for (final r in study) {
      final d = (r['difficulty'] ?? -1) as int;
      if (d == 0) difficultyCounts['again'] = (difficultyCounts['again'] ?? 0) + 1;
      if (d == 1) difficultyCounts['hard']  = (difficultyCounts['hard']  ?? 0) + 1;
      if (d == 3) difficultyCounts['good']  = (difficultyCounts['good']  ?? 0) + 1;
      if (d == 5) difficultyCounts['easy']  = (difficultyCounts['easy']  ?? 0) + 1;
    }

    int correct = 0, incorrect = 0;
    for (final r in quiz) {
      if (r['is_correct'] == true) correct++; else incorrect++;
    }

    // Word difficulty map
    final wordTally = <String, Map<String, int>>{};
    for (final r in study) {
      final w = (r['word'] ?? '').toString();
      final d = (r['difficulty'] ?? -1) as int;
      wordTally.putIfAbsent(w, () => {'again':0,'hard':0,'good':0,'easy':0});
      if (d == 0) wordTally[w]!['again'] = (wordTally[w]!['again'] ?? 0) + 1;
      if (d == 1) wordTally[w]!['hard']  = (wordTally[w]!['hard']  ?? 0) + 1;
    }
    final quizMiss = <String, int>{};
    for (final r in quiz) {
      final w = (r['word'] ?? '').toString();
      if (r['is_correct'] == false) {
        quizMiss[w] = (quizMiss[w] ?? 0) + 1;
      }
    }

    List<MapEntry<String, int>> hardestAgain = wordTally.entries
      .map((e) => MapEntry(e.key, e.value['again'] ?? 0))
      .toList()
      ..sort((a,b)=>b.value.compareTo(a.value));
    hardestAgain = hardestAgain.where((e)=>e.value>0).take(10).toList();

    List<MapEntry<String, int>> hardestQuiz = quizMiss.entries.toList()
      ..sort((a,b)=>b.value.compareTo(a.value));
    hardestQuiz = hardestQuiz.take(10).toList();

    final totalStudy = study.length;
    final totalQuiz = quiz.length;
    final accuracy = totalQuiz == 0 ? 0 : ((correct / totalQuiz) * 100).round();

    return {
      'summary': {
        'total_study': totalStudy,
        'total_quiz': totalQuiz,
        'again': difficultyCounts['again'],
        'hard': difficultyCounts['hard'],
        'good': difficultyCounts['good'],
        'easy': difficultyCounts['easy'],
        'quiz_correct': correct,
        'quiz_incorrect': incorrect,
        'quiz_accuracy_percent': accuracy,
      },
      'top_again_words': [
        for (final e in hardestAgain) {'word': e.key, 'again': e.value}
      ],
      'top_quiz_missed': [
        for (final e in hardestQuiz) {'word': e.key, 'missed': e.value}
      ],
    };
  }

  String _buildAiPrompt(List<dynamic> records) {
    // Bound the records sent to AI to keep tokens safe
    const cap = 600; // send at most 600 recent records
    final limited = records.take(cap).toList();

    final aggregates = _buildAggregates(records);

    final payload = {
      'period': _selectedPeriod,
      'user': widget.userName,
      'record_count': records.length,
      'aggregates': aggregates,
      'records': limited.map((r) {
        return {
          'type': r['type'],
          'word': r['word'],
          'difficulty': r['type']=='study' ? r['difficulty'] : null,
          'is_correct': r['type']=='quiz' ? r['is_correct'] : null,
          'datetime': r['studied_at'] ?? r['completed_at'],
        };
      }).toList(),
      'note': records.length > cap ? 'truncated_to_first_${cap}_records' : 'full',
    };

    final jsonPayload = const JsonEncoder.withIndent('  ').convert(payload);

    final prompt = '''You are a supportive learning coach. Analyze the user's study (spaced repetition difficulties) and quiz history, then produce:
- A brief progress report for the selected period.
- Strengths and weaknesses (skill patterns, types of errors).
- Top focus words/concepts to review.
- A concrete study plan for next period (daily/weekly targets, techniques, timing).
- 3-5 actionable tips to improve retention and test accuracy.

Constraints:
- Be concise and student-friendly.
- Use bullet points where helpful.
- If data is sparse, state limitations and give general advice.

Here is the JSON data to analyze:
```json
$jsonPayload
```
Return the final answer as readable markdown.
''';
    return prompt;
  }

  Future<void> _runAnalysis() async {
    setState(() { _analyzing = true; _aiResult = null; });
    try {
      final ai = AIService();
      final apiKey = await ai.getAiApiKey();
      if (apiKey.isEmpty) {
        throw Exception('No AI API key configured. Set it in Settings.');
      }
      final prompt = _buildAiPrompt(_filtered);
      final result = await ai.analyzeStudyHistory(prompt);
      if (!mounted) return;
      setState(() { _aiResult = result; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() { _analyzing = false; });
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Suggestions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick a time period to analyze your study and quiz history. The AI will summarize your progress and suggest what to do next.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Period: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const ['Weekly','Monthly','Quarterly','Yearly']
                    .map((p)=>DropdownMenuItem(value:p, child: Text(p)))
                    .toList(),
                  onChanged: (v) {
                    if (v==null) return;
                    setState(() { _selectedPeriod = v; _applyPeriodFilter(); _aiResult = null; });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _filtered.isEmpty || _analyzing ? null : _runAnalysis,
                icon: const Icon(Icons.analytics),
                label: Text(_analyzing ? 'Analyzing...' : 'Analyze'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatesView() {
    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No records found for $_selectedPeriod period', style: TextStyle(color: Colors.grey.shade700)),
      );
    }
    final agg = _buildAggregates(_filtered);
    final s = agg['summary'] as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Snapshot ($_selectedPeriod)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _chip('Study', s['total_study'].toString(), Colors.blue),
              _chip('Quiz', s['total_quiz'].toString(), Colors.purple),
              _chip('Again', s['again'].toString(), Colors.red),
              _chip('Hard', s['hard'].toString(), Colors.orange),
              _chip('Good', s['good'].toString(), Colors.blueGrey),
              _chip('Easy', s['easy'].toString(), Colors.green),
              _chip('Accuracy', '${s['quiz_accuracy_percent']}%', Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text('$label: $value', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAiResult() {
    if (_analyzing) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_aiResult == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SelectableText(_aiResult!, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Suggestions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildAggregatesView(),
                  _buildAiResult(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
