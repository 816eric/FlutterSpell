import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/spell_api_service.dart';
import '../services/tts_helper.dart';

  int _deckLimit = 10;
  String? _deckTag;
  bool _settingsLoaded = false;

class StudyPage extends StatefulWidget {
  final String userName;
  const StudyPage({super.key, required this.userName});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  final FlutterTts tts = FlutterTts();

  List<dynamic> _cards = [];
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  String? _emptyReason;
  String _effectiveUserName = '';
  bool _shouldShowLogin = false;

  @override
  void initState() {
    super.initState();
    // Don't load deck here, wait for didChangeDependencies to get latest userName
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newUserName = (widget.userName.isEmpty) ? 'Guest' : widget.userName;
    final userChanged = newUserName != _effectiveUserName;
    _effectiveUserName = newUserName;
    if (_effectiveUserName.isEmpty || _effectiveUserName == 'Guest') {
      if (!_shouldShowLogin) {
        _shouldShowLogin = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please Login first')),
          );
        });
      }
      setState(() {
        _loading = false;
        _settingsLoaded = false;
        _cards = [];
      });
    } else {
      if (_shouldShowLogin) {
        setState(() {
          _shouldShowLogin = false;
        });
      }
      // Always reload settings/deck if user changed or not loaded
      setState(() {
        _loading = true;
        _settingsLoaded = false;
        _cards = [];
      });
      _loadUserSettingsAndDeck();
    }
  }
  Future<void> _loadUserSettingsAndDeck() async {
    setState(() { _loading = true; });
    try {
      final profile = await SpellApiService.getUserProfile(_effectiveUserName);
        final userId = profile['id'] ?? null;
        Map<String, dynamic>? settings;
        if (userId != null) {
          settings = await SpellApiService.getUserSettings(userId);
        }
        // Default values if no settings
        _deckLimit = settings?['num_study_words'] ?? 10;
        final studyWordsSource = settings?['study_words_source'] ?? 'ALL_TAGS';
        if (studyWordsSource == 'ALL_TAGS') {
          _deckTag = null;
        } else {
          _deckTag = await SpellApiService.getLatestLoginTag(_effectiveUserName);
        }
      _settingsLoaded = true;
      await _loadDeck();
    } catch (e) {
      // fallback to defaults
      _deckLimit = 10;
      _deckTag = null;
      _settingsLoaded = true;
      await _loadDeck();
    }
  }


  Future<void> _loadDeck() async {
    // No need to redirect here; handled in _refreshUserAndDeck
    setState(() { _loading = true; });
    try {
      final deck = await SpellApiService.getDeck(_effectiveUserName, _deckLimit, tag: _deckTag);
      _cards = deck['cards'] ?? [];
      _emptyReason = deck['empty_reason'];
      _index = 0;
      _revealed = false;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load deck: $e'))
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _revealAndPlay() async {
    if (_cards.isEmpty) return;
    setState(() { _revealed = true; });
    final card = _cards[_index];
    await TtsHelper.playWord(
      context: context,
      tts: tts,
      word: card['text'] ?? '',
      repeatCount: 1,
    );
  }

  Future<void> _rate(int quality) async {
    if (_cards.isEmpty) return;
    final card = _cards[_index];
    if (_index + 1 < _cards.length) {
      setState(() { _index++; _revealed = false; });
    } else {
      // Only submit review after last card
      try {
        await SpellApiService.submitReview(widget.userName, card['word_id'], quality);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e'))
        );
        return;
      }
      setState(() { _revealed = false; });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('All done for today!'),
          content: const Text('Great job. Come back tomorrow for more.'),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop(); },
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    String title = "You're all set!";
    String body = "No cards to study.";
    if (_emptyReason == "no_tags") {
      title = "No tags yet";
      body = "Assign tags to words to build your study deck.";
    } else if (_emptyReason == "no_words") {
      title = "No words found";
      body = "Add words or assign tags first.";
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDeck,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShowLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: const Center(child: Text('Please Login first', style: TextStyle(fontSize: 20))),
      );
    }
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: _buildEmptyState(),
      );
    }
    final card = _cards[_index];
    final progress = "${_index + 1}/${_cards.length}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text(progress)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card['text'] ?? '',
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _revealAndPlay,
              icon: const Icon(Icons.volume_up),
              label: Text(_revealed ? "Play again" : "Play"),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: _revealed ? () => _rate(0) : null,
                    child: const Text('Again'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _revealed ? () => _rate(1) : null,
                    child: const Text('Hard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _revealed ? () => _rate(3) : null,
                    child: const Text('Good'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _revealed ? () => _rate(5) : null,
                    child: const Text('Easy'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
