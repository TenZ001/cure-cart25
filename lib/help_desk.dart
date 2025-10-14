import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpDeskScreen extends StatelessWidget {
  const HelpDeskScreen({Key? key}) : super(key: key);

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: '+94771234567');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@curecart.app',
      queryParameters: {
        'subject': 'Support request from CureCart app',
        'body': 'Describe your issue here...\n\nDevice: \nApp Version: ',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Desk'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Support (Hotline)'),
              subtitle: const Text('+94 77 123 4567'),
              onTap: _callSupport,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email Support'),
              subtitle: const Text('support@curecart.app'),
              onTap: _emailSupport,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'FAQ & Knowledge Base',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _FaqTile(
            title: 'Common ordering issues',
            items: const [
              'Order not delivered',
              'Incorrect item received',
              'Unable to place order',
            ],
          ),
          _FaqTile(
            title: 'Prescription upload failed',
            items: const [
              'Ensure the image is clear and well-lit',
              'File size under 10MB',
              'Stable internet connection',
            ],
          ),
          _FaqTile(
            title: 'Account & login support',
            items: const [
              'Reset password from Login screen',
              'Contact support if email not recognized',
              'Verify you selected the correct role',
            ],
          ),
          _FaqTile(
            title: 'Guide for uploading prescriptions',
            items: const [
              'Tap Prescriptions > Upload Prescription',
              'Take a clear photo of full document',
              'Submit and wait for pharmacy approval',
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FaqTile({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: items
            .map((t) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.help_outline, size: 18),
                  title: Text(t),
                ))
            .toList(),
      ),
    );
  }
}


