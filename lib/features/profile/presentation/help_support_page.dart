import 'package:flutter/material.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/profile/presentation/tutorial_page.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildQuickAction(
            context,
            title: 'How to use Sharoni',
            subtitle: 'Quick visual tutorial for beginners',
            icon: Icons.auto_stories_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TutorialPage())),
          ),
          const SizedBox(height: 32),
          
          _buildSectionHeader('Frequently Asked Questions'),
          _buildFAQTile(
            'Is the AI diagnosis accurate?',
            'The AI uses BioMistral, a specialized medical model. However, it is an assistant, not a replacement for a doctor. Always seek professional help for serious symptoms.',
          ),
          _buildFAQTile(
            'What is the Escalation System?',
            'If you miss a medication dose, the app can automatically message your emergency contact to ensure your safety.',
          ),
          _buildFAQTile(
            'What are Critical Alerts?',
            'These are high-priority notifications for life-saving meds that will alert you even if your phone is on silent.',
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Support & Feedback'),
          _buildActionTile(
            title: 'Report a Bug / AI Error',
            subtitle: 'Did the AI misunderstand a regional expression?',
            icon: Icons.bug_report_outlined,
            onTap: () => _showReportForm(context),
          ),
          _buildActionTile(
            title: 'Contact Support',
            subtitle: 'Get in touch with our clinical team',
            icon: Icons.mail_outline,
            onTap: () {},
          ),

          const SizedBox(height: 48),
          Center(
            child: Text(
              'Designed to improve healthcare accessibility.',
              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportForm(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report AI Misinterpretation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Please describe the regional expression or clinical error you encountered.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. The AI didn\'t understand the term "pepperish" for a burning sensation...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you! Your feedback helps us improve clinical accuracy.')),
                  );
                },
                child: const Text('Submit Feedback'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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

  Widget _buildQuickAction(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
