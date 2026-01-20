import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({Key? key}) : super(key: key);

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Legal")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.blue),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
            onTap: () => _launchUrl(context, 'https://aispell.pages.dev/privacy-policy.html'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.green),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
            onTap: () => _launchUrl(context, 'https://aispell.pages.dev/terms-of-service.html'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Data Deletion'),
            trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
            onTap: () => _launchUrl(context, 'https://aispell.pages.dev/data-deletion.html'),
          ),
        ],
      ),
    );
  }
}
