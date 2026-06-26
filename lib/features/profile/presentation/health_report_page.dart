import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:sharoni/core/models/medication_log.dart';
import 'package:sharoni/core/models/symptom.dart';
import 'package:sharoni/core/models/profile.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/features/medication/presentation/medication_controller.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';

class HealthReportPage extends ConsumerWidget {
  const HealthReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final medicationsAsync = ref.watch(medicationControllerProvider);
    final logsAsync = ref.watch(medicationLogsProvider);
    final symptomsAsync = ref.watch(symptomControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: profileAsync.when(
        data: (profile) => medicationsAsync.when(
          data: (medications) => symptomsAsync.when(
            data: (symptoms) {
              final logs = logsAsync.value ?? [];
              return _ReportBody(
                profile: profile,
                userEmail: user?.email ?? '',
                medications: medications,
                logs: logs,
                symptoms: symptoms,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final Profile? profile;
  final String userEmail;
  final List<Medication> medications;
  final List<MedicationLog> logs;
  final List<Symptom> symptoms;

  const _ReportBody({
    required this.profile,
    required this.userEmail,
    required this.medications,
    required this.logs,
    required this.symptoms,
  });

  double get _adherenceRate {
    if (logs.isEmpty) return 1.0;
    final taken = logs.where((l) => l.status.toLowerCase() == 'taken').length;
    return taken / logs.length;
  }

  String get _adherenceLabel {
    final rate = _adherenceRate;
    if (rate >= 0.9) return 'Excellent';
    if (rate >= 0.75) return 'Good';
    if (rate >= 0.5) return 'Moderate';
    return 'Poor';
  }

  Color get _adherenceColor {
    final rate = _adherenceRate;
    if (rate >= 0.9) return const Color(0xFF10B981); // Emerald
    if (rate >= 0.75) return const Color(0xFF3B82F6); // Blue
    if (rate >= 0.5) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  String _formatMeasurement(String? val, String type) {
    if (val == null || val.isEmpty) return 'Not recorded';
    final unit = profile?.measurementUnit ?? 'metric';
    if (type == 'height') {
      return unit == 'metric' ? '$val cm' : "$val in";
    } else {
      return unit == 'metric' ? '$val kg' : '$val lbs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: const Color(0xFF1A2340),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'Medicare Health Report ($dateStr) - Adherence: ${(_adherenceRate * 100).toInt()}% ($_adherenceLabel)',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report summary copied to clipboard!')),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A2340), Color(0xFF2D3F70)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_hospital_outlined, size: 14, color: Colors.white70),
                            SizedBox(width: 6),
                            Text(
                              'MEDICARE HEALTH REPORT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile?.username != null && profile!.username!.isNotEmpty
                        ? 'For: ${profile!.username}'
                        : userEmail.split('@').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated on $dateStr',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Patient Info Card
              _buildPatientInfoCard(),
              const SizedBox(height: 16),

              // Adherence Summary
              _buildAdherenceSummary(),
              const SizedBox(height: 16),

              // Medication Breakdown
              _buildMedicationBreakdown(),
              const SizedBox(height: 16),

              // Symptom History
              _buildSymptomHistory(),
              const SizedBox(height: 16),

              // Emergency Contact Info
              _buildEmergencyContact(),
              const SizedBox(height: 16),

              // Alerts & Flags
              _buildAlertsSection(),
              const SizedBox(height: 32),

              // Footer
              _buildFooter(dateStr),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Sections ────────────────────────────────────────────────────────────────

  Widget _buildPatientInfoCard() {
    return _ReportCard(
      headerIcon: Icons.person_outlined,
      headerColor: const Color(0xFF4A6DFB),
      title: 'Patient Information',
      child: Column(
        children: [
          _infoRow('Full Name', profile?.username ?? userEmail.split('@').first.replaceAll('.', ' ').toUpperCase()),
          _infoRow('Email', userEmail),
          _infoRow('Age', profile?.age?.isNotEmpty == true ? '${profile!.age} years' : 'Not recorded'),
          _infoRow('Sex', profile?.sex ?? 'Not recorded'),
          _infoRow('Blood Type', profile?.bloodType ?? 'Not recorded'),
          _infoRow('Genotype', profile?.genotype ?? 'Not recorded'),
          _infoRow('Height', _formatMeasurement(profile?.height, 'height')),
          _infoRow('Weight', _formatMeasurement(profile?.weight, 'weight')),
          if (profile?.medicalConditions?.isNotEmpty == true)
            _infoRow('Medical Conditions', profile!.medicalConditions!),
          if (profile?.allergies?.isNotEmpty == true)
            _infoRow('Known Allergies', profile!.allergies!, valueColor: const Color(0xFFE53935)),
          _infoRow('Report Date', DateFormat('MMM d, yyyy – h:mm a').format(DateTime.now())),
        ],
      ),
    );
  }

  Widget _buildAdherenceSummary() {
    final pct = (_adherenceRate * 100).toInt();

    return _ReportCard(
      headerIcon: Icons.analytics_outlined,
      headerColor: _adherenceColor,
      title: 'Medication Adherence Overview',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _adherenceColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _adherenceColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          _adherenceLabel,
          style: TextStyle(
            color: _adherenceColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$pct%',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _adherenceRate,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(_adherenceColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statPill(
                label: 'Total Scheduled',
                value: '${logs.length}',
                color: const Color(0xFF4A6DFB),
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(width: 10),
              _statPill(
                label: 'Taken Doses',
                value: '${logs.where((l) => l.status.toLowerCase() == 'taken').length}',
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _statPill(
                label: 'Missed / Skipped',
                value: '${logs.where((l) => l.status.toLowerCase() != 'taken').length}',
                color: const Color(0xFFEF4444),
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationBreakdown() {
    if (medications.isEmpty) {
      return _ReportCard(
        headerIcon: Icons.medication_outlined,
        headerColor: const Color(0xFF00BFA6),
        title: 'Prescribed Medications',
        child: _emptyState('No medication programs recorded.'),
      );
    }

    return _ReportCard(
      headerIcon: Icons.medication_outlined,
      headerColor: const Color(0xFF00BFA6),
      title: 'Prescribed Medications',
      child: Column(
        children: medications.map((med) {
          final medLogs = logs.where((l) => l.medicationId == med.id).toList();
          final medTaken = medLogs.where((l) => l.status.toLowerCase() == 'taken').length;
          final rate = medLogs.isEmpty ? 1.0 : medTaken / medLogs.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '${(rate * 100).toInt()}% Adherence',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: rate >= 0.8 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Dosage: ${med.dosagePerIntake}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled times: ${med.scheduledTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      med.isEnabled ? Icons.check_circle : Icons.pause_circle_filled,
                      size: 14,
                      color: med.isEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      med.isEnabled ? 'Active schedule' : 'Paused schedule',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSymptomHistory() {
    if (symptoms.isEmpty) {
      return _ReportCard(
        headerIcon: Icons.healing_outlined,
        headerColor: const Color(0xFFFFB020),
        title: 'Recent Symptoms Logged',
        child: _emptyState('No symptoms logged in the system.'),
      );
    }

    // Sort symptoms: most recent first
    final sortedSymptoms = List<Symptom>.from(symptoms)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _ReportCard(
      headerIcon: Icons.healing_outlined,
      headerColor: const Color(0xFFFFB020),
      title: 'Recent Symptoms Logged',
      child: Column(
        children: sortedSymptoms.take(5).map((symptom) {
          final formattedDate = DateFormat('MMM d, yyyy').format(symptom.createdAt);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        symptom.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                if (symptom.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: symptom.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB020).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (symptom.possibleCauses != null && symptom.possibleCauses!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Possible Cause: ${symptom.possibleCauses}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmergencyContact() {
    final contactName = profile?.emergencyContactName;
    final contactPhone = profile?.emergencyContactPhone;
    final relationship = profile?.emergencyContactRelationship;

    if (contactName == null || contactName.isEmpty) {
      return _ReportCard(
        headerIcon: Icons.contact_phone_outlined,
        headerColor: const Color(0xFF8B5CF6),
        title: 'Emergency Contact & Care Circle',
        child: _emptyState('No emergency contact specified.'),
      );
    }

    return _ReportCard(
      headerIcon: Icons.contact_phone_outlined,
      headerColor: const Color(0xFF8B5CF6),
      title: 'Emergency Contact & Care Circle',
      child: Column(
        children: [
          _infoRow('Contact Name', contactName),
          if (relationship != null && relationship.isNotEmpty) _infoRow('Relationship', relationship),
          if (contactPhone != null && contactPhone.isNotEmpty) _infoRow('Phone Number', contactPhone),
          _infoRow(
            'Escalation Alerts',
            profile?.escalationEnabled == true ? 'ENABLED (Auto-sync notifications active)' : 'DISABLED',
            valueColor: profile?.escalationEnabled == true ? const Color(0xFF10B981) : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    final missedCount = logs.where((l) => l.status.toLowerCase() != 'taken').length;
    final consecutiveMissed = _calculateConsecutiveMissed();

    final List<_AlertItem> alerts = [];

    if (consecutiveMissed >= 3) {
      alerts.add(
        _AlertItem(
          title: 'CRITICAL ESCALATION TRIGGERED',
          message: 'Patient has missed $consecutiveMissed consecutive doses. Alerts pushed to emergency contacts.',
          type: _AlertType.critical,
        ),
      );
    } else if (missedCount > 5) {
      alerts.add(
        _AlertItem(
          title: 'High Non-Adherence Alert',
          message: 'Patient has missed a total of $missedCount doses in this tracking cycle.',
          type: _AlertType.warning,
        ),
      );
    }

    if (profile?.escalationEnabled != true) {
      alerts.add(
        const _AlertItem(
          title: 'Escalation Off',
          message: 'Automatic messaging to doctors/emergency contact is disabled.',
          type: _AlertType.info,
        ),
      );
    }

    if (alerts.isEmpty) {
      return const _ReportCard(
        headerIcon: Icons.notifications_active_outlined,
        headerColor: Color(0xFF10B981),
        title: 'Active Flags & Warnings',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No critical health alerts active. Patient behavior fits normal parameters.',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _ReportCard(
      headerIcon: Icons.notifications_active_outlined,
      headerColor: const Color(0xFFEF4444),
      title: 'Active Flags & Warnings',
      child: Column(
        children: alerts,
      ),
    );
  }

  Widget _buildFooter(String dateStr) {
    return Column(
      children: [
        const Divider(color: Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        const Text(
          'Medicare Health Report Systems',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          'Export verification token: HS_${profile?.id.hashCode ?? '000'}_$dateStr',
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }

  // ── Helper Logic & UI ────────────────────────────────────────────────────────

  int _calculateConsecutiveMissed() {
    // Sort logs: chronologically reversed
    final sortedLogs = List<MedicationLog>.from(logs)
      ..sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));

    int consecutive = 0;
    for (final log in sortedLogs) {
      if (log.status.toLowerCase() != 'taken') {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: Colors.grey[400], fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}

// ───── Presentation Widgets ──────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final IconData headerIcon;
  final Color headerColor;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _ReportCard({
    required this.headerIcon,
    required this.headerColor,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(headerIcon, color: headerColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2340),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

enum _AlertType { critical, warning, info }

class _AlertItem extends StatelessWidget {
  final String title;
  final String message;
  final _AlertType type;

  const _AlertItem({
    required this.title,
    required this.message,
    required this.type,
  });

  Color get _color {
    switch (type) {
      case _AlertType.critical:
        return const Color(0xFFEF4444);
      case _AlertType.warning:
        return const Color(0xFFF59E0B);
      case _AlertType.info:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            type == _AlertType.critical
                ? Icons.error
                : (type == _AlertType.warning ? Icons.warning : Icons.info),
            color: _color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _color),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}