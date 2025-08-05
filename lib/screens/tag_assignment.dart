
import 'package:flutter/material.dart';
import '../services/spell_api_service.dart';


// Multi-level tree node for tag hierarchy
class _TagTreeNode {
  final String label;
  final List<_TagTreeNode> children;
  dynamic tag; // Only leaf nodes have tag
  _TagTreeNode(this.label, {List<_TagTreeNode>? children}) : children = children ?? [];
}

class TagAssignmentPage extends StatefulWidget {
  final String userName;

  const TagAssignmentPage({super.key, required this.userName});

  @override
  State<TagAssignmentPage> createState() => _TagAssignmentPageState();
}


class _TagAssignmentPageState extends State<TagAssignmentPage> {
  bool _shouldShowLogin = false;
  List<dynamic> allTags = [];
  List<dynamic> userTags = [];
  List<dynamic> availableTags = [];
  Set<int> selectedAvailableTagIds = {};
  Set<int> selectedAssignedTagIds = {};
  Map<int, dynamic> tagIdToTag = {};
  Set<int> expandedAvailableGroups = {};
  Set<int> expandedAssignedGroups = {};

  @override
  void initState() {
    super.initState();
    final user = widget.userName;
    if (user.isEmpty || user == 'Guest') {
      _shouldShowLogin = true;
      // Delay navigation to allow build to complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please Login first')),
        );
        Navigator.of(context).pushReplacementNamed('/settings');
      });
    } else {
      fetchTags();
    }
  }

  Future<void> fetchTags() async {
    final all = await SpellApiService.getAllTags();
    final user = await SpellApiService.getUserTags(widget.userName);
    setState(() {
      allTags = all;
      userTags = user;
      tagIdToTag = {for (var t in all + user) t['id']: t};
      _updateAvailableTags();
      selectedAvailableTagIds.clear();
      selectedAssignedTagIds.clear();
    });
  }

  void _updateAvailableTags() {
    final userTagIds = userTags.map((t) => t['id']).toSet();
    availableTags = allTags.where((t) => !userTagIds.contains(t['id'])).toList();
  }

  Future<void> assignTags() async {
    if (selectedAvailableTagIds.isEmpty) return;
    await SpellApiService.assignTagsToUser(widget.userName, selectedAvailableTagIds.toList());
    await fetchTags();
  }

  Future<void> unassignTags() async {
    if (selectedAssignedTagIds.isEmpty) return;
    await SpellApiService.unassignTagsFromUser(widget.userName, selectedAssignedTagIds.toList());
    await fetchTags();
  }

  Future<void> deleteTag(int tagId) async {
    await SpellApiService.deleteUserTag(widget.userName, tagId);
    await fetchTags();
  }


  // Build a tree from tag list
  List<_TagTreeNode> _buildTagTreeNodes(List<dynamic> tags) {
    final Map<String, _TagTreeNode> roots = {};
    for (var tag in tags) {
      final name = tag['name'] ?? tag['tag'] ?? '';
      final parts = name.split('::');
      _addTagToTree(roots, parts, 0, tag);
    }
    return roots.values.toList();
  }

  void _addTagToTree(Map<String, _TagTreeNode> currentLevel, List<String> parts, int index, dynamic tag) {
    final part = parts[index];
    _TagTreeNode node = currentLevel[part] ?? _TagTreeNode(part);
    currentLevel[part] = node;
    if (index == parts.length - 1) {
      // Leaf node
      node.tag = tag;
    } else {
      // Find or create child node map
      Map<String, _TagTreeNode> childMap = {for (var c in node.children) c.label: c};
      _addTagToTree(childMap, parts, index + 1, tag);
      // Update children list to reflect all children
      node.children
        ..clear()
        ..addAll(childMap.values);
    }
  }

  Widget _buildTagTreeWidget(List<_TagTreeNode> nodes, Set<int> selectedIds, Set<int> expandedGroups, bool isAssigned, [String parentPath = '', int level = 0]) {
    return ListView(
      shrinkWrap: true,
      children: nodes.map((node) {
        final path = parentPath.isEmpty ? node.label : '$parentPath::${node.label}';
        final groupId = path.hashCode;
        if (node.children.isNotEmpty) {
          // Expand all by default
          if (!expandedGroups.contains(groupId)) expandedGroups.add(groupId);
          return Container(
            margin: EdgeInsets.only(left: 16.0 * level),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('group-$groupId-$isAssigned'),
                title: Row(
                  children: [
                    Icon(Icons.folder, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(node.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                initiallyExpanded: true,
                trailing: expandedGroups.contains(groupId)
                    ? const Icon(Icons.remove, color: Colors.black)
                    : const Icon(Icons.add, color: Colors.black),
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      expandedGroups.add(groupId);
                    } else {
                      expandedGroups.remove(groupId);
                    }
                  });
                },
                children: [
                  _buildTagTreeWidget(node.children, selectedIds, expandedGroups, isAssigned, path, level + 1),
                ],
              ),
            ),
          );
        } else if (node.tag != null) {
          return Container(
            margin: EdgeInsets.only(left: 16.0 * level),
            child: _buildTagTile(node.tag, selectedIds, isAssigned),
          );
        } else {
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _buildTagTree(List<dynamic> tags, Set<int> selectedIds, Set<int> expandedGroups, bool isAssigned) {
    final nodes = _buildTagTreeNodes(tags);
    return _buildTagTreeWidget(nodes, selectedIds, expandedGroups, isAssigned);
  }

  Widget _buildTagTile(dynamic tag, Set<int> selectedIds, bool isAssigned) {
    final tagId = tag['id'];
    final tagName = tag['name'] ?? tag['tag'] ?? '';
    final isUserOwned = tag['owner'] == widget.userName;
    return ListTile(
      leading: Checkbox(
        value: selectedIds.contains(tagId),
        onChanged: (selected) {
          setState(() {
            if (selected == true) {
              selectedIds.add(tagId);
            } else {
              selectedIds.remove(tagId);
            }
          });
        },
      ),
      title: Text(tagName),
      trailing: isAssigned && isUserOwned
          ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete tag',
              onPressed: () => deleteTag(tagId),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShowLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Tag Assignment")),
        body: const Center(child: Text('Please Login first', style: TextStyle(fontSize: 20))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Tag Assignment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left: Available tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Available Tags", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildTagTree(availableTags, selectedAvailableTagIds, expandedAvailableGroups, false),
                  ),
                  ElevatedButton(
                    onPressed: assignTags,
                    child: const Text("Assign →"),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 32),
            // Right: Assigned tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Assigned Tags", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildTagTree(userTags, selectedAssignedTagIds, expandedAssignedGroups, true),
                  ),
                  ElevatedButton(
                    onPressed: unassignTags,
                    child: const Text("← Unassign"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}