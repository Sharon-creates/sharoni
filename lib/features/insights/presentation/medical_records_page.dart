import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';
import 'package:sharoni/features/medication/presentation/medication_controller.dart';
import 'package:sharoni/core/models/symptom.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:intl/intl.dart';

class MedicalRecordsPage extends ConsumerStatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  ConsumerState<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends ConsumerState<MedicalRecordsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _exportData() {
    // Placeholder for CSV/PDF export logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating clinical health report (CSV)...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symptomsAsync = ref.watch(symptomControllerProvider);
    final medicationsAsync = ref.watch(medicationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Symptom History'),
            Tab(text: 'Medication Archive'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportData,
            tooltip: 'Export Records',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSymptomHistory(symptomsAsync),
          _buildMedicationArchive(medicationsAsync),
        ],
      ),
    );
  }

  Widget _buildSymptomHistory(AsyncValue<List<Symptom>> symptomsAsync) {
    return symptomsAsync.when(
      data: (symptoms) => symptoms.isEmpty
          ? _buildEmptyState('No symptom logs found.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: symptoms.length,
              itemBuilder: (context, index) => _buildSymptomRecordTile(symptoms[index]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMedicationArchive(AsyncValue<List<Medication>> medicationsAsync) {
    return medicationsAsync.when(
      data: (meds) {
        final archivedMeds = meds.where((m) => m.isArchived || (!m.isEnabled && m.endDate != null)).toList();
        return archivedMeds.isEmpty
            ? _buildEmptyState('No archived medications found.')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: archivedMeds.length,
                itemBuilder: (context, index) => _buildMedicationRecordTile(archivedMeds[index]),
              );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSymptomRecordTile(Symptom symptom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          symptom.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(DateFormat('MMM dd, yyyy • HH:mm').format(symptom.createdAt)),
            if (symptom.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: symptom.tags.take(3).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t, style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                )).toList(),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Show details dialog or navigate
          _showSymptomDetail(symptom);
        },
      ),
    );
  }

  Widget _buildMedicationRecordTile(Medication med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.medication_outlined, color: Colors.grey),
        ),
        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Completed on ${DateFormat('MMM dd, yyyy').format(med.endDate ?? med.createdAt)}'),
        trailing: const Icon(Icons.info_outline),
      ),
    );
  }

  void _showSymptomDetail(Symptom symptom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Record Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailItem('Reported Symptom', symptom.description),
              _buildDetailItem('Date & Time', DateFormat('MMMM dd, yyyy • HH:mm').format(symptom.createdAt)),
              const SizedBox(height: 16),
              _buildDetailItem('Clinical Analysis', symptom.analysisResult ?? 'No analysis available'),
              _buildDetailItem('Possible Causes', symptom.possibleCauses ?? 'Not identified'),
              _buildDetailItem('First Aid Advice', symptom.firstAid ?? 'No specific advice given'),
              if (symptom.followUpQuestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Follow-up Interrogation', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 8),
                ...List.generate(symptom.followUpQuestions.length, (i) {
                  final q = symptom.followUpQuestions[i];
                  final a = symptom.followUpAnswers.length > i ? symptom.followUpAnswers[i] : 'No answer provided';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q: $q', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('A: $a', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
