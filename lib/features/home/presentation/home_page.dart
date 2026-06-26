import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/medication/presentation/medication_controller.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/features/home/presentation/navigation_controller.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:sharoni/core/models/medication_log.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final medications = ref.watch(medicationControllerProvider).value ?? [];
    final symptoms = ref.watch(symptomControllerProvider).value ?? [];
    final logsAsync = ref.watch(medicationLogsProvider);

    final activeMeds = medications.where((m) => m.isEnabled).length;
    final recentSymptoms = symptoms.take(3).toList();

    // Calculate upcoming doses for today
    final List<Map<String, dynamic>> upcomingDoses = [];
    final now = DateTime.now();
    for (final med in medications.where((m) => m.isEnabled)) {
      for (final time in med.scheduledTimes) {
        final scheduledFor = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        upcomingDoses.add({
          'med': med,
          'time': time,
          'scheduledFor': scheduledFor,
        });
      }
    }
    upcomingDoses.sort((a, b) => (a['scheduledFor'] as DateTime).compareTo(b['scheduledFor'] as DateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicare'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, profile?.username ?? 'User'),
            const SizedBox(height: 24),
            _buildQuickStatusCard(context, ref, activeMeds, symptoms.length),
            const SizedBox(height: 24),
            
            // Missed Dose Warning Banner
            if (logsAsync.hasValue)
              _buildMissedDoseWarning(upcomingDoses, logsAsync.value!),

            _buildSectionTitle('Today\'s Schedule'),
            const SizedBox(height: 16),
            logsAsync.when(
              data: (logs) => _buildMedicationDashboard(context, ref, upcomingDoses, logs),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )),
              error: (e, st) {
                debugPrint('Schedule error: $e');
                return _buildErrorCard('Unable to load schedule. Please try again.');
              },
            ),
            const SizedBox(height: 24),


            if (recentSymptoms.isNotEmpty) ...[
              _buildSectionTitle('Recent Activity'),
              const SizedBox(height: 16),
              ...recentSymptoms.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () => ref.read(navigationControllerProvider.notifier).state = 1,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_edu, color: AppTheme.secondaryColor, size: 24),
                  ),
                  title: Text(
                    s.description, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(_formatDate(s.createdAt), style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 13)),
                  ),
                  trailing: Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                ),
              )),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('Care Modules'),
            const SizedBox(height: 16),
            _buildQuickActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationDashboard(
    BuildContext context, 
    WidgetRef ref, 
    List<Map<String, dynamic>> upcomingDoses, 
    List<MedicationLog> logs
  ) {
    final totalDosesToday = upcomingDoses.length;
    
    // Only count logs that correspond to the medications and times in today's upcoming doses
    final takenDosesToday = upcomingDoses.where((dose) {
      final med = dose['med'] as Medication;
      final scheduledFor = dose['scheduledFor'] as DateTime;
      return logs.any((l) => 
        l.medicationId == med.id && 
        l.status == 'taken' &&
        l.scheduledFor.hour == scheduledFor.hour && 
        l.scheduledFor.minute == scheduledFor.minute
      );
    }).length;

    final progressValue = totalDosesToday > 0 
        ? (takenDosesToday / totalDosesToday).clamp(0.0, 1.0) 
        : 0.0;

    return Column(
      children: [
        if (totalDosesToday > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '$takenDosesToday/$totalDosesToday',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Adherence', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Keep it up! Consistency is key.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ...upcomingDoses.take(4).map((dose) {
          final med = dose['med'] as Medication;
          final time = dose['time'] as TimeOfDay;
          final scheduledFor = dose['scheduledFor'] as DateTime;
          
          // Find matching log for this specific time slot
          MedicationLog? log;
          for (final l in logs) {
            if (l.medicationId == med.id &&
                l.scheduledFor.hour == scheduledFor.hour &&
                l.scheduledFor.minute == scheduledFor.minute) {
              log = l;
              break;
            }
          }
          
          final String status = log?.status.toLowerCase() ?? 'pending';
          final bool isTaken = status == 'taken';
          final bool isSkipped = status == 'skipped';
          final bool isIgnored = status == 'ignored' || status == 'missed';

          IconData leadingIcon = Icons.radio_button_unchecked;
          Color leadingColor = Colors.grey[400]!;
          if (isTaken) {
            leadingIcon = Icons.check_circle;
            leadingColor = AppTheme.primaryColor;
          } else if (isSkipped) {
            leadingIcon = Icons.next_plan;
            leadingColor = Colors.orange;
          } else if (isIgnored) {
            leadingIcon = Icons.error;
            leadingColor = Colors.red;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(leadingIcon, color: leadingColor),
              title: Text(
                med.name, 
                style: TextStyle(
                  decoration: isTaken ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                  color: isTaken ? Colors.grey : AppTheme.accentColor,
                ),
              ),
              subtitle: Text('${time.format(context)} • ${med.dosagePerIntake}'),
              trailing: isTaken
                  ? const Text('Taken', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
                  : isSkipped
                      ? const Text('Skipped', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                      : isIgnored
                          ? const Text('Ignored', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    ref.read(medicationControllerProvider.notifier).logDose(med.id, scheduledFor, 'taken');
                                    ref.invalidate(medicationLogsProvider);
                                  },
                                  child: const Text('Take'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref.read(medicationControllerProvider.notifier).logDose(med.id, scheduledFor, 'skipped');
                                    ref.invalidate(medicationLogsProvider);
                                  },
                                  child: const Text('Skip', style: TextStyle(color: Colors.orange)),
                                ),
                              ],
                            ),
            ),
          );
        }),
        if (upcomingDoses.isEmpty)
          CustomPaint(
            painter: DashedRectPainter(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              strokeWidth: 1.5,
              gap: 6,
              dashWidth: 6,
              radius: 16,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy, color: AppTheme.textSecondary.withValues(alpha: 0.7), size: 36),
                  const SizedBox(height: 12),
                  const Text('No doses scheduled for today', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMissedDoseWarning(List<Map<String, dynamic>> upcomingDoses, List<MedicationLog> logs) {
    final now = DateTime.now();
    int missedCount = 0;

    for (final dose in upcomingDoses) {
      final scheduledFor = dose['scheduledFor'] as DateTime;
      if (scheduledFor.isBefore(now.subtract(const Duration(hours: 1)))) {
        final isTaken = logs.any((l) => 
          l.medicationId == (dose['med'] as Medication).id && 
          l.scheduledFor.hour == scheduledFor.hour && 
          l.scheduledFor.minute == scheduledFor.minute
        );
        if (!isTaken) missedCount++;
      }
    }

    if (missedCount < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attention: Missed Doses',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
                      ),
                      Text(
                        'You have missed $missedCount doses today. For your safety, consistency is important.',
                        style: TextStyle(fontSize: 13, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Repeatedly missing medications can impact treatment efficacy. Please consult your healthcare provider if you have concerns about your schedule.',
              style: TextStyle(fontSize: 12, color: Colors.red[900], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusCard(BuildContext context, WidgetRef ref, int activeMeds, int totalSymptoms) {
    return Row(
      children: [
        Expanded(
          child: _statusItem(
            'Active Meds',
            activeMeds.toString(),
            Icons.medication,
            AppTheme.primaryColor,
            onTap: () => ref.read(navigationControllerProvider.notifier).state = 2,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statusItem(
            'Symptoms Logged',
            totalSymptoms.toString(),
            Icons.history,
            AppTheme.secondaryColor,
            onTap: () => ref.read(navigationControllerProvider.notifier).state = 1,
          ),
        ),
      ],
    );
  }

  Widget _statusItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildWelcomeCard(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF4AC4A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How are you feeling today? Track your symptoms or check your reminders.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppTheme.accentColor,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3, // Reduced from 1.5 to allow more height
      children: [
        _buildActionCard(
          context,
          'Symptom Tracker',
          Icons.add_chart,
          AppTheme.secondaryColor,
          onTap: () => ref.read(navigationControllerProvider.notifier).state = 1,
        ),
        _buildActionCard(
          context,
          'Medication Reminders',
          Icons.medication,
          AppTheme.primaryColor,
          onTap: () => ref.read(navigationControllerProvider.notifier).state = 2,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double radius;

  DashedRectPainter({
    this.color = Colors.grey, 
    this.strokeWidth = 1.0, 
    this.gap = 5.0,
    this.dashWidth = 5.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    path.addRRect(rrect);

    Path dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
