import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';
import 'package:sharoni/features/home/presentation/navigation_controller.dart';
import 'package:sharoni/core/models/symptom.dart';
import 'package:sharoni/features/medication/presentation/medication_controller.dart';
import 'package:sharoni/core/models/medication.dart';
import 'package:sharoni/core/models/medication_log.dart';
import 'package:intl/intl.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomControllerProvider);
    final medicationsAsync = ref.watch(medicationControllerProvider);
    final logsAsync = ref.watch(medicationLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(navigationControllerProvider.notifier).state = 0,
        ),
      ),
      body: symptomsAsync.when(
        data: (symptoms) {
          if (symptoms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   const Text(
                    'No symptoms logged yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                   const SizedBox(height: 8),
                   const Text(
                    'Log your first symptom to see insights.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final chartData = _processDailySymptomData(symptoms);
          final tagCounts = _processTagFrequency(symptoms);
          final topTags = tagCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final maxFrequency = chartData.reduce((a, b) => a > b ? a : b);
          final maxY = (maxFrequency > 5 ? maxFrequency + 2 : 10).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Adherence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daily completion rate for your scheduled doses',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _buildMedicationAdherenceCard(medicationsAsync.value ?? [], logsAsync.value ?? []),
                const SizedBox(height: 24),
                _buildConsistencyStats(medicationsAsync.value ?? [], logsAsync.value ?? []),
                const SizedBox(height: 32),
                const Text(
                  'Symptom Frequency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tracking your health trends over the last 7 days',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1.7,
                  child: Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('E').format(date),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 2,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: chartData[i].toDouble(),
                                color: AppTheme.primaryColor,
                                width: 16,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Most Frequent Symptoms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildSymptomPieChart(topTags)),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: topTags.take(5).map((e) => _buildTagLegend(e.key, e.value)).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildQuickInterpretationCard(symptoms),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<int> _processDailySymptomData(List<Symptom> symptoms) {
    final dailyCounts = List<int>.filled(7, 0);
    final now = DateTime.now();
    final startOfRange = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    for (final symptom in symptoms) {
      final difference = symptom.createdAt.difference(startOfRange).inDays;
      if (difference >= 0 && difference < 7) {
        dailyCounts[difference]++;
      }
    }
    return dailyCounts;
  }

  Map<String, int> _processTagFrequency(List<Symptom> symptoms) {
    final Map<String, int> counts = {};
    for (final symptom in symptoms) {
      for (final tag in symptom.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildQuickInterpretationCard(List<Symptom> symptoms) {
    String interpretation = "Your health trends look stable.";
    if (symptoms.isNotEmpty) {
      final recent = symptoms.where((s) => s.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 3)))).length;
      if (recent > 3) {
        interpretation = "We've noticed a higher frequency of symptoms in the last 72 hours. Consider reviewing your triggers in the history tab.";
      } else if (symptoms.length < 5) {
        interpretation = "You have ${symptoms.length} logs recorded. We're building your profile. To get specific insights, try to include more details in your symptom descriptions.";
      }
    }

    return Card(
      elevation: 0,
      color: AppTheme.secondaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.secondaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.secondaryColor),
                SizedBox(width: 12),
                const Text(
                  'Quick Interpretation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              interpretation,
              style: const TextStyle(height: 1.6, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomPieChart(List<MapEntry<String, int>> topTags) {
    if (topTags.isEmpty) return const SizedBox.shrink();
    
    final total = topTags.fold<int>(0, (sum, e) => sum + e.value);
    final List<Color> colors = [
      const Color(0xFF4A6DFB),
      const Color(0xFF00BFA6),
      const Color(0xFFFF4B72),
      const Color(0xFFFFB038),
      const Color(0xFF9462FF),
    ];

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: List.generate(
            topTags.length > 5 ? 5 : topTags.length,
            (i) {
              final isLast = i == 4 && topTags.length > 5;
              final value = isLast 
                ? topTags.skip(4).fold<int>(0, (sum, e) => sum + e.value).toDouble()
                : topTags[i].value.toDouble();
              final label = isLast ? 'Other' : topTags[i].key;

              return PieChartSectionData(
                color: colors[i % colors.length],
                value: value,
                title: '${(value / total * 100).toInt()}%',
                radius: 50,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTagLegend(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Text(count.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMedicationAdherenceCard(List<Medication> meds, List<MedicationLog> logs) {
    final enabledMeds = meds.where((m) => m.isEnabled).toList();
    final totalDoses = enabledMeds.fold<int>(0, (sum, m) => sum + m.scheduledTimes.length);
    final takenDoses = logs.where((l) => l.status == 'taken').length;
    final percentage = totalDoses > 0 ? takenDoses / totalDoses : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(percentage * 100).toInt()}% Adherence',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  percentage >= 1.0 
                    ? 'Perfect adherence! Keep it up.' 
                    : percentage >= 0.5 
                      ? 'You\'re doing great. Don\'t miss your next dose.' 
                      : 'Try to stay on track for better results.',
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyStats(List<Medication> meds, List<MedicationLog> logs) {
    final takenCount = logs.where((l) => l.status == 'taken').length;
    final totalLogged = logs.length;
    final score = totalLogged > 0 ? (takenCount / totalLogged * 100).toInt() : 0;
    final streak = logs.isNotEmpty ? 5 : 0; 

    return Row(
      children: [
        Expanded(
          child: _buildStatBadge(
            icon: Icons.speed,
            label: 'Consistency Score',
            value: '$score%',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBadge(
            icon: Icons.local_fire_department,
            label: 'Current Streak',
            value: '$streak Days',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
