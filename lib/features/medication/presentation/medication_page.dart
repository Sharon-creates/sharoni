import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/medication/presentation/medication_controller.dart';
import 'package:sharoni/features/home/presentation/navigation_controller.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:sharoni/core/models/medication_log.dart';
import 'package:sharoni/features/medication/data/medication_repository.dart';

class MedicationPage extends ConsumerStatefulWidget {
  const MedicationPage({super.key});

  @override
  ConsumerState<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends ConsumerState<MedicationPage> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _durationController = TextEditingController();
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];


  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _showAddMedication(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Medication',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return await ref.read(medicationRepositoryProvider).searchDrugs(textEditingValue.text);
                },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                  if (textEditingController.text != _nameController.text) {
                    textEditingController.text = _nameController.text;
                  }
                  textEditingController.addListener(() {
                    _nameController.text = textEditingController.text;
                  });

                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                    decoration: InputDecoration(
                      labelText: 'Drug Name',
                      hintText: 'e.g., Paracetamol',
                      prefixIcon: const Icon(Icons.medication, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: 'Dosage per intake',
                  hintText: 'e.g., 1 tablet, 5 ml',
                  prefixIcon: const Icon(Icons.scale, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Scheduled Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setModalState) => Column(
                  children: [
                    ..._selectedTimes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final time = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(context: context, initialTime: time);
                                  if (picked != null) {
                                    setModalState(() => _selectedTimes[index] = picked);
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                                      const SizedBox(width: 12),
                                      Text(time.format(context), style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedTimes.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setModalState(() => _selectedTimes.removeAt(index));
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() => _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0)));
                        setState(() {});
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add another time'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Quantity',
                        hintText: 'e.g., 30',
                        prefixIcon: const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Duration (days)',
                        hintText: 'Optional',
                        prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter both Drug Name and Dosage')),
                      );
                      return;
                    }

                    try {
                      await ref.read(medicationControllerProvider.notifier).addMedication(
                        name: _nameController.text,
                        dosagePerIntake: _dosageController.text,
                        scheduledTimes: _selectedTimes,
                        totalQuantity: int.tryParse(_quantityController.text),
                        durationDays: int.tryParse(_durationController.text),
                      );
                      _nameController.clear();
                      _dosageController.clear();
                      _quantityController.clear();
                      _durationController.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Save Medication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationControllerProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: medicationsAsync.when(
          data: (medications) {
            if (medications.isEmpty) return _buildEmptyState();

            final logs = ref.watch(medicationLogsProvider).value ?? [];
            
            // Calculate actual progress from logs
            final totalDosesToday = medications.where((m) => m.isEnabled).fold<int>(0, (sum, m) => sum + m.scheduledTimes.length);
            final takenDosesToday = logs.where((l) => l.status == 'taken').length;
            final progress = totalDosesToday > 0 ? (takenDosesToday / totalDosesToday).clamp(0.0, 1.0) : 0.0;

            final morningMeds = medications.where((m) => m.scheduledTimes.any((t) => t.hour < 12)).toList();
            final eveningMeds = medications.where((m) => m.scheduledTimes.any((t) => t.hour >= 12)).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Medications',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your daily medications',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B7BFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.link, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Today's Progress Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Progress",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$takenDosesToday of $totalDosesToday medications taken',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Morning Section
                  if (morningMeds.isNotEmpty) ...[
                    _buildTimeSectionHeader('Morning', '08:00 AM', Icons.wb_sunny_outlined, const Color(0xFFFFF7E6), const Color(0xFFFFB020)),
                    const SizedBox(height: 16),
                    ...morningMeds.map((med) {
                      final log = logs.cast<MedicationLog?>().firstWhere(
                        (l) => l!.medicationId == med.id && l.scheduledFor.hour < 12,
                        orElse: () => null,
                      );
                      final status = log?.status.toLowerCase() ?? 'pending';
                      final isCompleted = status != 'pending';
                      
                      Color baseCol = const Color(0xFFFFEFE9);
                      Color iconCol = const Color(0xFFFF7A45);
                      if (status == 'taken') {
                        baseCol = const Color(0xFFE6FAF6);
                        iconCol = const Color(0xFF00BFA6);
                      } else if (status == 'skipped') {
                        baseCol = const Color(0xFFFFF7E6);
                        iconCol = Colors.orange;
                      } else if (status == 'ignored' || status == 'missed') {
                        baseCol = const Color(0xFFFEF2F2);
                        iconCol = Colors.red;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildMedicationCard(context, ref, med, isCompleted: isCompleted, status: status, baseColor: baseCol, iconColor: iconCol),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Evening Section
                  if (eveningMeds.isNotEmpty) ...[
                    _buildTimeSectionHeader('Evening', '08:00 PM', Icons.nightlight_round_outlined, const Color(0xFFF3EDFF), const Color(0xFF9462FF)),
                    const SizedBox(height: 16),
                    ...eveningMeds.map((med) {
                      final log = logs.cast<MedicationLog?>().firstWhere(
                        (l) => l!.medicationId == med.id && l.scheduledFor.hour >= 12,
                        orElse: () => null,
                      );
                      final status = log?.status.toLowerCase() ?? 'pending';
                      final isCompleted = status != 'pending';

                      Color baseCol = const Color(0xFFFFEFE9);
                      Color iconCol = const Color(0xFFFF7A45);
                      if (status == 'taken') {
                        baseCol = const Color(0xFFE6FAF6);
                        iconCol = const Color(0xFF00BFA6);
                      } else if (status == 'skipped') {
                        baseCol = const Color(0xFFFFF7E6);
                        iconCol = Colors.orange;
                      } else if (status == 'ignored' || status == 'missed') {
                        baseCol = const Color(0xFFFEF2F2);
                        iconCol = Colors.red;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildMedicationCard(context, ref, med, isCompleted: isCompleted, status: status, baseColor: baseCol, iconColor: iconCol),
                      );
                    }),
                    const SizedBox(height: 100), // padding for FAB
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedication(context),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTimeSectionHeader(String title, String time, IconData icon, Color bgColor, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationCard(
    BuildContext context, 
    WidgetRef ref, 
    Medication med, {
    required bool isCompleted, 
    required String status,
    required Color baseColor, 
    required Color iconColor
  }) {
    final isTaken = status == 'taken';
    final isSkipped = status == 'skipped';
    final isIgnored = status == 'ignored' || status == 'missed';

    IconData? trailingIcon;
    Color trailingColor = Colors.grey[400]!;
    if (isTaken) {
      trailingIcon = Icons.check;
      trailingColor = AppTheme.primaryColor;
    } else if (isSkipped) {
      trailingIcon = Icons.next_plan;
      trailingColor = Colors.orange;
    } else if (isIgnored) {
      trailingIcon = Icons.error;
      trailingColor = Colors.red;
    }

    return InkWell(
      onTap: () {
        if (!isCompleted) {
          final now = DateTime.now();
          final hour = med.scheduledTimes.any((t) => t.hour < 12) ? 8 : 20;
          final scheduledFor = DateTime(now.year, now.month, now.day, hour);

          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                    title: const Text('Mark as Taken'),
                    onTap: () {
                      ref.read(medicationControllerProvider.notifier).logDose(med.id, scheduledFor, 'taken');
                      ref.invalidate(medicationLogsProvider);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${med.name} marked as taken')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.next_plan, color: Colors.orange),
                    title: const Text('Mark as Skipped'),
                    onTap: () {
                      ref.read(medicationControllerProvider.notifier).logDose(med.id, scheduledFor, 'skipped');
                      ref.invalidate(medicationLogsProvider);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${med.name} marked as skipped')),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTaken ? const Color(0xFFF2FBF9) : isSkipped ? const Color(0xFFFFFDF5) : isIgnored ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTaken ? const Color(0xFFA6E5D9) : isSkipped ? Colors.orange[200]! : isIgnored ? Colors.red[200]! : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medication, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${med.dosagePerIntake} · Daily',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? trailingColor : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: isCompleted && trailingIcon != null
                  ? Icon(trailingIcon, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_outlined, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Keep track of your meds',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first medication to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
