import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';

class RewardPage extends StatefulWidget {
  final String? currentUserName; // null -> not logged in
  const RewardPage({super.key, this.currentUserName});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final TextEditingController _itemCtrl = TextEditingController();
  final TextEditingController _pointsCtrl = TextEditingController();

  bool _loading = false;
  int _currentPoints = 0;

  // history
  int _page = 1;
  int _total = 0;
  static const int pageSize = 20;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
  if (widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest') return;
  await Future.wait([_loadPoints(), _loadHistory(1)]);
  }

  Future<void> _loadPoints() async {
  if (widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest') return;
    setState(() { _loading = true; });
    try {
      final res = await SpellApiService.getPoints(widget.currentUserName!);
      setState(() {
        _currentPoints = (res['total_points'] ?? 0) as int;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load points: $e')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _redeem() async {
  if (widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest') return;
    final item = _itemCtrl.text.trim();
    final ptsStr = _pointsCtrl.text.trim();
    if (item.isEmpty || ptsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill item and points')));
      return;
    }
    final pts = int.tryParse(ptsStr) ?? 0;
    if (pts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points must be a positive number')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Redeem'),
        content: Text('Redeem $pts points for "$item"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { _loading = true; });
    try {
      final res = await SpellApiService.redeemPoints(widget.currentUserName!, item, pts);
      // success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redeemed successfully')));
      _itemCtrl.clear();
      _pointsCtrl.clear();
      await _loadPoints();
      await _loadHistory(1);
    } catch (e) {
      final msg = e.toString().contains('insufficient_points')
          ? 'Points are not sufficient.'
          : 'Redeem failed: $e';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _loadHistory(int page) async {
  if (widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest') return;
    setState(() { _loading = true; });
    try {
      final res = await SpellApiService.getRewardHistory(widget.currentUserName!, page: page);
      setState(() {
        _page = (res['page'] ?? 1) as int;
        _total = (res['total'] ?? 0) as int;
        _history = (res['items'] ?? []) as List<dynamic>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Widget _buildRedeemSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Redeem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.currentUserName ?? ''} - Total Points: $_currentPoints',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _itemCtrl,
              decoration: const InputDecoration(labelText: 'Item name', hintText: 'e.g., Sticker Pack'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Points to redeem', hintText: 'e.g., 30'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _redeem,
                icon: const Icon(Icons.redeem),
                label: const Text('Redeem'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(Map item) {
    final ts = item['timestamp'] ?? '';
    final action = item['action'] ?? '';
    final pts = item['points'] ?? 0;
    final reason = item['reason'] ?? '';
    final isRedeem = action == 'redeem';

    return ListTile(
      leading: Icon(isRedeem ? Icons.remove_circle_outline : Icons.add_circle_outline,
          color: isRedeem ? Colors.red : Colors.green),
      title: Text(reason.isNotEmpty ? reason : action.toString().toUpperCase()),
      subtitle: Text(ts.toString()),
      trailing: Text(
        pts.toString(),
        style: TextStyle(color: isRedeem ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHistorySection() {
    final totalPages = (_total / pageSize).ceil();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Redeem & Reward History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No history yet.')),
              )
            else
              ..._history.map((e) => _buildHistoryRow(e as Map)).toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page $_page of ${totalPages == 0 ? 1 : totalPages}'),
                Row(
                  children: [
                    TextButton(
                      onPressed: _page > 1 ? () => _loadHistory(_page - 1) : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: (_page < totalPages) ? () => _loadHistory(_page + 1) : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notLoggedIn = widget.currentUserName == null || widget.currentUserName!.isEmpty || widget.currentUserName == 'Guest';
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: notLoggedIn
          ? const Center(child: Text('Please login first'))
          : RefreshIndicator(
              onRefresh: () async { await _initData(); },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading) const LinearProgressIndicator(),
                  _buildRedeemSection(),
                  const SizedBox(height: 12),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }
}
