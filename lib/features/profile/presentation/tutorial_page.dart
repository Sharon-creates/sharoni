import 'package:flutter/material.dart';
import 'package:sharoni/core/theme.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Mastering Sharoni AI',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Learn how to use your clinical diagnostic assistant effectively.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          _buildStep(
            number: '01',
            title: 'Reporting Symptoms',
            content: 'Be as descriptive as possible. Instead of "Stomach pain," try "Sharp pain in lower right abdomen for 2 hours." The BioMistral AI works best with specific details.',
            icon: Icons.chat_bubble_outline,
            color: Colors.blue,
          ),
          
          _buildStep(
            number: '02',
            title: 'AI Analysis & Triage',
            content: 'After logging, look for the "Urgency Level." If the AI suggests "Emergency," seek medical help immediately. The AI also provides "First Aid" steps you can take at home.',
            icon: Icons.auto_awesome_outlined,
            color: Colors.purple,
          ),

          _buildStep(
            number: '03',
            title: 'Managing Medications',
            content: 'Add your prescriptions in the "Reminders" tab. Enable "Critical Alerts" for life-saving drugs to ensure you never miss a dose, even during "Do Not Disturb" hours.',
            icon: Icons.medication_outlined,
            color: Colors.pink,
          ),

          _buildStep(
            number: '04',
            title: 'Tagging & Trends',
            content: 'Add tags like "Work Stress" or "Post-Workout" to your logs. This helps your doctor identify environmental factors that might be triggering your symptoms.',
            icon: Icons.label_outline,
            color: Colors.orange,
          ),

          _buildStep(
            number: '05',
            title: 'Regional Expressions',
            content: 'The AI is learning! If you use a local expression (e.g., "I feel pepperish") and the AI doesn\'t understand, please use the "Report Bug" feature to help us improve.',
            icon: Icons.public_outlined,
            color: Colors.green,
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('I Understand, Let\'s Go!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
