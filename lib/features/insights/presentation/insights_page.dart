import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';
import 'package:sharoni/features/home/presentation/navigation_controller.dart';
import 'package:sharoni/core/models/symptom.dart';
import 'package:intl/intl.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomControllerProvider);

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
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppTheme.primaryColor,
                              tooltipRoundedRadius: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.toInt().toString(),
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
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
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (index) {
                            return _makeGroupData(index, chartData[index].toDouble());
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (topTags.isNotEmpty) ...[
                  const Text(
                    'Most Frequent Symptoms',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: topTags.take(5).map((entry) => _buildTagFrequencyChip(entry.key, entry.value)).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
                _buildInsightSummary(symptoms, topTags.map((e) => e.key).toList()),
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
    // Get the start of today (00:00:00)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List.filled(7, 0);
    
    for (var symptom in symptoms) {
      // Get the start of the day the symptom was created
      final createdDate = DateTime(
        symptom.createdAt.year, 
        symptom.createdAt.month, 
        symptom.createdAt.day
      );
      
      // Calculate day difference (0 = today, 1 = yesterday, etc.)
      final difference = today.difference(createdDate).inDays;
      
      if (difference >= 0 && difference < 7) {
        // Map to the correct bar (0 = 6 days ago, 6 = today)
        counts[6 - difference]++;
      }
    }
    return counts;
  }

  Map<String, int> _processTagFrequency(List<Symptom> symptoms) {
    final Map<String, int> frequency = {};
    for (var symptom in symptoms) {
      for (var tag in symptom.tags) {
        frequency[tag] = (frequency[tag] ?? 0) + 1;
      }
    }
    return frequency;
  }

  Widget _buildTagFrequencyChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF8E99F3)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0, // Placeholder if we wanted a background rod
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightSummary(List<Symptom> symptoms, List<String> topTags) {
    String interpretation = "You haven't logged enough symptoms yet for a detailed analysis.";
    if (symptoms.isNotEmpty) {
      if (topTags.isNotEmpty) {
        final topThree = topTags.take(3).map((t) => t.toUpperCase()).join(', ');
        interpretation = "Over the past week, your most frequent reports involved: **$topThree**. ";
        
        if (symptoms.length > 8) {
          interpretation += "\n\nWe've noticed a high frequency of symptoms. It may be helpful to discuss this 7-day trend with your healthcare provider.";
        } else if (symptoms.length > 5) {
          interpretation += "\n\nYou've been tracking regularly. Consistency helps in identifying specific triggers for your $topThree.";
        } else {
          interpretation += "\n\nContinue logging daily to help us identify potential patterns and triggers for your health conditions.";
        }
      } else {
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
                Text(
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
}
