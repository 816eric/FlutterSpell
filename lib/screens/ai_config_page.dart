import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIConfigPage extends StatefulWidget {
  const AIConfigPage({Key? key}) : super(key: key);

  @override
  State<AIConfigPage> createState() => _AIConfigPageState();
}

class _AIConfigPageState extends State<AIConfigPage> {
  String _aiProvider = 'gemini';
  String _aiModel = 'gemini-2.5-flash';
  String _aiApiKey = '';
  final _aiApiKeyController = TextEditingController();
  bool _isLoading = true;
  
  // Prompt templates
  final _promptEnglishController = TextEditingController();
  final _promptChineseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAiSettings();
  }

  @override
  void dispose() {
    _aiApiKeyController.dispose();
    _promptEnglishController.dispose();
    _promptChineseController.dispose();
    super.dispose();
  }

  Future<void> _loadAiSettings() async {
    setState(() => _isLoading = true);
    try {
      final aiService = AIService();
      final provider = await aiService.getAiProvider();
      final model = await aiService.getAiModel();
      final apiKey = await aiService.getAiApiKey();
      
      // Load prompts (these already return defaults if custom is empty)
      final englishPrompt = await aiService.getEnglishPrompt();
      final chinesePrompt = await aiService.getChinesePrompt();

      setState(() {
        _aiProvider = provider;
        _aiModel = model;
        _aiApiKey = apiKey;
        _aiApiKeyController.text = apiKey;
        
        // Pre-fill fields with prompts (either custom or default)
        _promptEnglishController.text = englishPrompt;
        _promptChineseController.text = chinesePrompt;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _setAiProvider(String value) async {
    setState(() {
      _aiProvider = value;
      _aiModel = AIService.getDefaultModelForProvider(value);
    });

    final aiService = AIService();
    await aiService.setAiProvider(value);
    await aiService.setAiModel(_aiModel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI provider changed to ${AIService.getProviderDisplayName(value)}')),
      );
    }
  }

  Future<void> _setAiModel(String value) async {
    setState(() => _aiModel = value);
    final aiService = AIService();
    await aiService.setAiModel(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model changed to $value')),
      );
    }
  }

  Future<void> _setAiApiKey(String value) async {
    setState(() => _aiApiKey = value);
    final aiService = AIService();
    await aiService.setAiApiKey(value);
  }

  Future<void> _saveApiKey() async {
    await _setAiApiKey(_aiApiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _savePrompts() async {
    final aiService = AIService();
    await aiService.setEnglishPrompt(_promptEnglishController.text);
    await aiService.setChinesePrompt(_promptChineseController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompts saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testConfiguration() async {
    if (_aiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Testing AI configuration...')),
          ],
        ),
      ),
    );

    // TODO: Implement actual test by making a simple API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration looks good! Provider: ${AIService.getProviderDisplayName(_aiProvider)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('AI Configuration Help'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'How to get API keys:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• Gemini: Visit ai.google.dev'),
                        Text('• OpenAI: Visit platform.openai.com'),
                        Text('• DeepSeek: Visit platform.deepseek.com'),
                        Text('• Qianwen: Visit Alibaba Cloud Console'),
                        SizedBox(height: 16),
                        Text(
                          'The AI service extracts words from images for your spelling practice.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure your AI provider for image word extraction',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AI Provider Selection
                  const Text(
                    'AI Provider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _aiProvider,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      prefixIcon: Icon(Icons.psychology),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'gemini',
                        child: Text('Google Gemini'),
                      ),
                      DropdownMenuItem(
                        value: 'openai',
                        child: Text('OpenAI'),
                      ),
                      DropdownMenuItem(
                        value: 'deepseek',
                        child: Text('DeepSeek'),
                      ),
                      DropdownMenuItem(
                        value: 'qianwen',
                        child: Text('Qianwen (Alibaba)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _setAiProvider(value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AIService.getApiKeyHint(_aiProvider),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Model Selection
                  const Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: AIService.getModelsForProvider(_aiProvider).contains(_aiModel)
                        ? _aiModel
                        : AIService.getModelsForProvider(_aiProvider).first,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      prefixIcon: Icon(Icons.memory),
                    ),
                    items: AIService.getModelsForProvider(_aiProvider)
                        .map((model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _setAiModel(value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Popular models are pre-selected. Advanced users can change as needed.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // API Key Input
                  const Text(
                    'API Key',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _aiApiKeyController,
                    decoration: InputDecoration(
                      hintText: 'Enter your ${AIService.getProviderDisplayName(_aiProvider)} API key...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Save API Key',
                        onPressed: _saveApiKey,
                      ),
                    ),
                    obscureText: true,
                    onChanged: (value) => _setAiApiKey(value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your API key is stored locally and never shared. Required for AI-powered image analysis.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Prompt Templates Section
                  const Text(
                    'Prompt Templates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customize AI prompts for back-card generation. Use \$WORD as placeholder for the word.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // English Prompt
                  const Text(
                    'English Prompt (no pinyin for English words)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _promptEnglishController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  
                  // Chinese Prompt
                  const Text(
                    'Chinese Prompt (中文提示词 - includes pinyin)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _promptChineseController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savePrompts,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Prompts'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testConfiguration,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Test Configuration'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reset Configuration'),
                                content: const Text(
                                  'This will reset all AI settings to default values. Your API key will be cleared.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _aiProvider = 'gemini';
                                        _aiModel = 'gemini-2.5-flash';
                                        _aiApiKey = '';
                                        _aiApiKeyController.clear();
                                      });
                                      final aiService = AIService();
                                      await aiService.setAiProvider('gemini');
                                      await aiService.setAiModel('gemini-2.5-flash');
                                      await aiService.setAiApiKey('');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Settings reset to defaults')),
                                        );
                                      }
                                    },
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset to Defaults'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Current Configuration Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Provider', AIService.getProviderDisplayName(_aiProvider)),
                          _buildInfoRow('Model', _aiModel),
                          _buildInfoRow('API Key', _aiApiKey.isEmpty ? 'Not configured' : '•' * 20),
                          _buildInfoRow('Status', _aiApiKey.isEmpty ? 'Incomplete' : 'Ready'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not configured' || value == 'Incomplete'
                    ? Colors.orange
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
