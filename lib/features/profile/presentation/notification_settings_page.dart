import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Standard Reminders'),
          _buildToggleTile(
            title: 'Enable Sound',
            subtitle: 'Play a tone for all health reminders',
            value: profile?.notifSound ?? true,
            icon: Icons.volume_up_outlined,
            onChanged: (val) => ref.read(profileControllerProvider.notifier).updateProfile(notifSound: val),
          ),
          _buildToggleTile(
            title: 'Vibration',
            subtitle: 'Haptic feedback for alerts',
            value: profile?.notifVibrate ?? true,
            icon: Icons.vibration_outlined,
            onChanged: (val) => ref.read(profileControllerProvider.notifier).updateProfile(notifVibrate: val),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader('High Priority Alerts'),
          _buildToggleTile(
            title: 'Critical Alerts',
            subtitle: 'Allow life-saving med alerts to bypass "Do Not Disturb"',
            value: profile?.criticalAlerts ?? false,
            icon: Icons.notification_important_outlined,
            iconColor: Colors.red,
            onChanged: (val) => ref.read(profileControllerProvider.notifier).updateProfile(criticalAlerts: val),
          ),
          _buildToggleTile(
            title: 'Escalation System',
            subtitle: 'Send external messages if medications are ignored',
            value: profile?.escalationEnabled ?? true,
            icon: Icons.security_outlined,
            onChanged: (val) => ref.read(profileControllerProvider.notifier).updateProfile(escalationEnabled: val),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Digest & Summary'),
          _buildToggleTile(
            title: 'Daily Digest',
            subtitle: 'Receive a morning summary of today\'s meds',
            value: profile?.dailyDigestEnabled ?? false,
            icon: Icons.summarize_outlined,
            onChanged: (val) => ref.read(profileControllerProvider.notifier).updateProfile(dailyDigestEnabled: val),
          ),
          
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Note: Some critical alerts may require system-level permissions on your device.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
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

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    Color? iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      activeColor: AppTheme.primaryColor,
    );
  }
}
