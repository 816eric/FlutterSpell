import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';
import '../services/ai_service.dart';

class QuizPage extends StatefulWidget {
  final String userName;
  const QuizPage({super.key, required this.userName});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool _loading = true;
  bool _generatingQuiz = false;
  String? _errorMessage;
  List<dynamic> _words = [];
  List<Map<String, dynamic>> _quizzes = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _showAnswer = false;
  
  // Track quiz history records for current session
  List<Map<String, dynamic>> _quizRecords = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() { _loading = true; _errorMessage = null; });
    
    final effectiveUserName = (widget.userName.isEmpty || widget.userName == 'Guest') 
        ? 'admin' 
        : widget.userName;

    try {
      // Get user's tags first (same logic as home page)
      final userTags = await SpellApiService.getUserTags(effectiveUserName);
      
      if (userTags.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = 'No tags found. Please add words and tags in My Words page first.';
        });
        return;
      }

      // Get the latest login tag or use first tag
      String? latestTag;
      try {
        latestTag = await SpellApiService.getLatestLoginTag(widget.userName);
      } catch (_) {
        latestTag = null;
      }

      final tagNames = userTags.map((e) => e['tag'] as String).toList();
      final selectedTag = (latestTag != null && tagNames.contains(latestTag)) 
          ? latestTag 
          : tagNames[0];

      // Fetch words for the selected tag (same as home page)
      final words = await SpellApiService.getWords(effectiveUserName, selectedTag);
      
      if (words.isEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = 'No words found for tag "$selectedTag". Please add words first.';
        });
        return;
      }

      setState(() {
        _words = words;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load words: $e';
      });
    }
  }

  Future<void> _generateQuizzes() async {
    setState(() { _generatingQuiz = true; _errorMessage = null; });

    try {
      final aiService = AIService();
      final apiKey = await aiService.getAiApiKey();
      
      // Check API key first
      if (apiKey.isEmpty) {
        setState(() {
          _generatingQuiz = false;
          _errorMessage = 'API key is not configured. Please go to Settings page and set your AI API key.';
        });
        return;
      }

      final quizzes = <Map<String, dynamic>>[];
      
      for (var word in _words) {
        try {
          final quiz = await aiService.generateQuiz(
            word['text'] as String,
            word['language'] as String? ?? 'en'
          );
          quizzes.add({
            'word': word['text'],
            ...quiz,
          });
        } catch (e) {
          print('Failed to generate quiz for ${word['text']}: $e');
        }
      }

      if (quizzes.isEmpty) {
        setState(() {
          _generatingQuiz = false;
          _errorMessage = 'Failed to generate any quizzes. Please try again.';
        });
        return;
      }

      setState(() {
        _quizzes = quizzes;
        _currentIndex = 0;
        _score = 0;
        _selectedAnswer = null;
        _showAnswer = false;
        _generatingQuiz = false;
      });
    } catch (e) {
      setState(() {
        _generatingQuiz = false;
        _errorMessage = 'Error generating quizzes: $e';
      });
    }
  }

  void _selectAnswer(int index) {
    if (_showAnswer) return;
    setState(() {
      _selectedAnswer = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _showAnswer) return;
    
    final currentQuiz = _quizzes[_currentIndex];
    final correctAnswer = currentQuiz['correct'] as int;
    final isCorrect = _selectedAnswer == correctAnswer;
    
    // Record this quiz answer
    _quizRecords.add({
      'word': currentQuiz['word'] as String,
      'is_correct': isCorrect,
    });
    
    if (isCorrect) {
      setState(() { _score++; });
    }
    
    setState(() { _showAnswer = true; });
  }

  void _nextQuestion() {
    if (_currentIndex < _quizzes.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showAnswer = false;
      });
    } else {
      _showFinalScore();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedAnswer = null;
        _showAnswer = false;
      });
    }
  }

  Future<void> _showFinalScore() async {
    // Save quiz history before showing results
    await _saveQuizHistory();
    
    // Award points based on score
    int pointsEarned = 0;
    if (widget.userName.isNotEmpty && widget.userName != 'Guest') {
      // Calculate points: 1 point per correct answer
      pointsEarned = _score;
      if (pointsEarned > 0) {
        try {
          await SpellApiService.addPoints(
            widget.userName,
            pointsEarned,
            'Quiz completed: $_score/${_quizzes.length} correct',
          );
        } catch (e) {
          print('Failed to award points: $e');
        }
      }
    }
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Text(
          'Your score: $_score / ${_quizzes.length}\n'
          '${(_score / _quizzes.length * 100).toStringAsFixed(1)}%'
          '${pointsEarned > 0 ? '\n\n🎉 Points Earned: $pointsEarned' : ''}'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _quizzes = [];
                _currentIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _showAnswer = false;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuizHistory() async {
    if (_quizRecords.isEmpty) return;
    if (widget.userName.isEmpty || widget.userName == 'Guest') return;
    
    try {
      await SpellApiService.saveQuizSession(widget.userName, _quizRecords);
      print('Quiz history saved: ${_quizRecords.length} records');
      _quizRecords.clear();
    } catch (e) {
      print('Failed to save quiz history: $e');
      // Don't show error to user, just log it
    }
  }

  Widget _buildStartScreen() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _errorMessage!.contains('API key') 
                    ? Icons.key_off 
                    : Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_errorMessage!.contains('API key'))
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to settings (index 4 in main.dart)
                    DefaultTabController.of(context).animateTo(4);
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Go to Settings'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _loadWords,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              '${_words.length} words available',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Generate AI quizzes to test your vocabulary!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generatingQuiz ? null : _generateQuizzes,
              icon: _generatingQuiz
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_generatingQuiz ? 'Generating...' : 'Generate Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final quiz = _quizzes[_currentIndex];
    final question = quiz['question'] as String;
    final options = quiz['options'] as List;
    final correctAnswer = quiz['correct'] as int;

    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1}/${_quizzes.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quiz['word'] as String,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // Question
                Text(
                  question,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                // Options
                ...List.generate(options.length, (index) {
                  final isSelected = _selectedAnswer == index;
                  final isCorrect = index == correctAnswer;
                  final showCorrect = _showAnswer && isCorrect;
                  final showWrong = _showAnswer && isSelected && !isCorrect;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: showCorrect
                              ? Colors.green.shade100
                              : showWrong
                                  ? Colors.red.shade100
                                  : isSelected
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: showCorrect
                                ? Colors.green
                                : showWrong
                                    ? Colors.red
                                    : isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: showCorrect
                                    ? Colors.green
                                    : showWrong
                                        ? Colors.red
                                        : isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    color: isSelected || showCorrect || showWrong
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[index] as String,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            if (showCorrect)
                              const Icon(Icons.check_circle, color: Colors.green),
                            if (showWrong)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Navigation buttons
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
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _showAnswer ? _nextQuestion : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _showAnswer
                        ? (_currentIndex < _quizzes.length - 1 ? 'Next' : 'Finish')
                        : 'Submit',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (_quizzes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _quizzes = [];
                  _currentIndex = 0;
                  _score = 0;
                  _selectedAnswer = null;
                  _showAnswer = false;
                });
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? _buildStartScreen()
              : _buildQuizScreen(),
    );
  }
}