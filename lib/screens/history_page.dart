import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';

class HistoryPage extends StatefulWidget {
  final String? currentUserName;
  const HistoryPage({super.key, this.currentUserName});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = false;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest') return;
    setState(() { _loading = true; });
    try {
      final historyResp = await SpellApiService.getLoginHistory(widget.currentUserName!);
      setState(() {
        _history = historyResp;
      });
    } catch (e) {
      // ignore or show error
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notLoggedIn = widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest';
    return Scaffold(
      appBar: AppBar(title: const Text('Login History')),
      body: notLoggedIn
          ? const Center(child: Text('Please login first'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? const Center(child: Text('No login history found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, idx) {
                        final entry = _history[idx];
                        final ts = entry['timestamp'] ?? '';
                        final tag = entry['tag'] ?? '';
                        return ListTile(
                          leading: const Icon(Icons.login),
                          title: Text('Tag: $tag'),
                          subtitle: Text(ts.toString()),
                        );
                      },
                    ),
    );
  }
}
