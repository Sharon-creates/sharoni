import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'dart:convert';

class PrivacySecurityPage extends ConsumerWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(
            title: 'How your data is used',
            content: 'Your symptom reports are processed by the BioMistral model (an expert-level medical LLM). This data is used solely to generate clinical insights and is not sold or shared with third-party advertisers.',
            icon: Icons.biotech_outlined,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Data Protection'),
          _buildSettingsTile(
            title: 'Medical Data Privacy',
            subtitle: 'Learn about our HIPAA-aligned encryption standards',
            icon: Icons.verified_user_outlined,
            onTap: () => _showPrivacyDetail(
              context, 
              'Medical Data Privacy', 
              '• AES-256 Encryption: All health records are encrypted at rest using industry-standard AES-256 protocols.\n\n'
              '• End-to-End Security: Data transmission between your device and our secure Supabase servers is protected by SSL/TLS 1.3.\n\n'
              '• Row-Level Security (RLS): Your medical data is strictly isolated. Only you, the authenticated owner, can access your symptom and medication logs.\n\n'
              '• Secure AI Processing: Clinical insights are generated in a transient, anonymous session. Your identity is never shared with the BioMistral model weights.',
            ),
          ),
          _buildSettingsTile(
            title: 'Privacy Policy',
            subtitle: 'Read the full terms of our "Early Access" program',
            icon: Icons.description_outlined,
            onTap: () => _showPrivacyDetail(
              context, 
              'Privacy Policy', 
              '1. Data Usage: We collect symptom and medication data solely to provide clinical insights and research trends.\n\n'
              '2. No Third-Party Sharing: We never sell or lease your medical information to advertisers or external vendors.\n\n'
              '3. Clinical Disclaimer: Sharoni is a research-based educational tool. It is NOT a certified medical device and should not be used for emergency diagnosis without professional consultation.\n\n'
              '4. Your Rights: Under our policy, you have the absolute right to download your health archive or delete your entire record at any time.',
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Account Management'),
          _buildSettingsTile(
            title: 'Download My Data',
            subtitle: 'Request a full archive of your health records',
            icon: Icons.download_outlined,
            onTap: () async {
              try {
                final data = await ref.read(profileControllerProvider.notifier).exportAllData();
                if (context.mounted) {
                  _showDataExportDialog(context, data);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
          ),
          _buildSettingsTile(
            title: 'Delete My Account',
            subtitle: 'Permanently wipe all health data from our servers',
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.red,
            onTap: () => _confirmDelete(context, ref),
          ),
          
          const SizedBox(height: 48),
          const Center(
            child: Text(
              'Version 1.0.0 (Early Access)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Sharoni Medical AI Platform',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDataExportDialog(BuildContext context, Map<String, dynamic> data) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Archive Ready'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your health records have been compiled from the secure database.'),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'In the production version, this file would be downloaded to your device.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              // On web, we could use dart:html to trigger download
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health report generated successfully!')));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDetail(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    String? selectedReason;
    final otherReasonController = TextEditingController();
    final reasons = [
      'Privacy Concerns',
      'Too difficult to use',
      'Found a better app',
      'Not useful for me',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We\'re sorry to see you go', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Before you delete your account permanently, could you tell us why you\'re leaving?',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 15)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: Colors.red,
                  onChanged: (val) => setModalState(() => selectedReason = val),
                  contentPadding: EdgeInsets.zero,
                )),
                if (selectedReason == 'Other')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: otherReasonController,
                      decoration: InputDecoration(
                        hintText: 'Please specify...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                const Text(
                  'Warning: This will permanently delete all your symptoms, medications, and profile data. This cannot be undone.',
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedReason == null ? null : () async {
                          Navigator.pop(context);
                          _showFinalDeleteConfirmation(context, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Everything?'),
        content: const Text(
          'This is your last chance. All your health data will be wiped from our secure servers forever.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
