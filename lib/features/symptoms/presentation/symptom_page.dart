import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/symptoms/presentation/symptom_controller.dart';
import 'package:sharoni/core/models/symptom.dart';
import 'package:sharoni/features/home/presentation/navigation_controller.dart';
import 'package:intl/intl.dart';

class SymptomPage extends ConsumerStatefulWidget {
  const SymptomPage({super.key});

  @override
  ConsumerState<SymptomPage> createState() => _SymptomPageState();
}

class _SymptomPageState extends ConsumerState<SymptomPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isAnalyzing = false;
  Symptom? _currentSymptom;
  final List<TextEditingController> _answerControllers = [];
  int? _expandedIndex;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    for (var c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _analyzeSymptoms() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _currentSymptom = null;
    });

    try {
      final symptom = await ref.read(symptomControllerProvider.notifier).analyzeAndSaveSymptom(_controller.text);
      
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _currentSymptom = symptom;
          _answerControllers.clear();
          for (var i = 0; i < (symptom.followUpQuestions.length); i++) {
            _answerControllers.add(TextEditingController());
          }
        });
      }
      
      _controller.clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing symptoms: $e')),
        );
      }
    }
  }

  void _submitAnswers() async {
    if (_currentSymptom == null) return;
    
    final answers = _answerControllers.map((c) => c.text).toList();
    if (answers.every((a) => a.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer at least one question.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final updatedSymptom = await ref.read(symptomControllerProvider.notifier).refineAndSaveSymptom(
        _currentSymptom!.id,
        _currentSymptom!.description,
        _currentSymptom!.followUpQuestions,
        answers,
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _currentSymptom = updatedSymptom;
          // Clear answers after submission if you want, or keep them
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis refined with your answers.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refining analysis: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptomsAsync = ref.watch(symptomControllerProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(navigationControllerProvider.notifier).state = 0,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Scrollbar(
            controller: _scrollController,
            thickness: 4,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  _buildInputCard(),
                  const SizedBox(height: 32),
                  if (_currentSymptom != null) ...[
                    _buildAnalysisCard(),
                    const SizedBox(height: 32),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Recent History',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  symptomsAsync.when(
                    data: (symptoms) => symptoms.isEmpty
                        ? _buildEmptyState()
                        : isWide
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: symptoms.length,
                                itemBuilder: (context, index) => _buildSymptomCard(symptoms[index], index),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: symptoms.length,
                                itemBuilder: (context, index) => _buildSymptomCard(symptoms[index], index),
                              ),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, st) => _buildErrorState(e.toString()),
                  ),
                  const SizedBox(height: 40),
                  _buildDisclaimer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., I have a sharp headache since morning and feel a bit dizzy...',
                labelText: 'How are you feeling?',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isAnalyzing
                  ? const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('AI is analyzing...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _analyzeSymptoms,
                      icon: const Icon(Icons.auto_awesome, size: 20),
                      label: const Text('Analyze & Log Symptoms'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    if (_currentSymptom == null) return const SizedBox.shrink();
    
    final needsClarification = _currentSymptom!.followUpQuestions.isNotEmpty && _currentSymptom!.followUpAnswers.isEmpty;
    
    return Card(
      elevation: 0,
      color: needsClarification ? const Color(0xFFFFF7ED) : AppTheme.primaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: needsClarification ? const Color(0xFFFED7AA) : AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(needsClarification ? Icons.pending_actions : Icons.auto_awesome, color: needsClarification ? Colors.orange : AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  needsClarification ? 'Clinical Refinement' : 'Final Health Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: needsClarification ? Colors.orange[800] : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (needsClarification)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your report is a bit vague. Please answer the questions below to help the AI refine its analysis.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            
            // Symptoms/Tags
            if (_currentSymptom!.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentSymptom!.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Possible Causes (Only show if not needing clarification)
            if (!needsClarification) ...[
              _buildInsightSection(
                icon: Icons.help_outline,
                title: 'Possible Causes',
                content: _currentSymptom!.possibleCauses ?? 'Unable to determine specific causes.',
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 20),

              // First Aid
              _buildInsightSection(
                icon: Icons.medical_services_outlined,
                title: 'First Aid Opinion',
                content: _currentSymptom!.firstAid ?? 'Consult a healthcare professional.',
                color: const Color(0xFFEC4899),
              ),
              const SizedBox(height: 20),
            ],

            // Summary
            _buildInsightSection(
              icon: Icons.info_outline,
              title: 'Advice',
              content: _currentSymptom!.analysisResult ?? 'Please monitor your condition.',
              color: AppTheme.primaryColor,
            ),

            // Triage Logic
            if (_currentSymptom!.followUpLogic != null && _currentSymptom!.followUpLogic!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildInsightSection(
                icon: Icons.psychology_outlined,
                title: 'Clinical Triage Logic',
                content: _currentSymptom!.followUpLogic!,
                color: const Color(0xFF8B5CF6),
              ),
            ],

            // Follow-up Questions & Answers
            if (_currentSymptom!.followUpQuestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.question_answer_outlined, size: 18, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Follow-up Questions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_currentSymptom!.followUpQuestions.length, (index) {
                      final q = _currentSymptom!.followUpQuestions[index];
                      final hasAnswered = _currentSymptom!.followUpAnswers.length > index && 
                                        _currentSymptom!.followUpAnswers[index].isNotEmpty;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            if (hasAnswered)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  _currentSymptom!.followUpAnswers[index],
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                                ),
                              )
                            else
                              TextField(
                                controller: _answerControllers[index],
                                decoration: InputDecoration(
                                  hintText: 'Your answer...',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                          ],
                        ),
                      );
                    }),
                    
                    // Show submit button only if there are unanswered questions
                    if (_currentSymptom!.followUpAnswers.isEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: _isAnalyzing
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : ElevatedButton.icon(
                              onPressed: _submitAnswers,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Refine Analysis'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI-generated advice. Not a substitute for professional medical evaluation.',
                      style: TextStyle(fontSize: 11, color: Colors.amber[900], fontWeight: FontWeight.bold),
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

  Widget _buildInsightSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomCard(Symptom symptom, int index) {
    final isExpanded = index == _expandedIndex;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isExpanded ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _expandedIndex = expanded ? index : null);
          },
          title: Text(
            symptom.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
              color: isExpanded ? AppTheme.primaryColor : AppTheme.accentColor,
            ),
          ),
          subtitle: Text(
            DateFormat('MMMM dd • HH:mm').format(symptom.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: isExpanded 
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(symptom.id),
              )
            : const Icon(Icons.expand_more),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (symptom.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: symptom.tags.map<Widget>((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    symptom.analysisResult ?? 'No analysis result available.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
                  ),
                  if (symptom.possibleCauses != null) ...[
                    const SizedBox(height: 16),
                    const Text('Possible Causes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(symptom.possibleCauses!, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                  if (symptom.firstAid != null) ...[
                    const SizedBox(height: 16),
                    const Text('First Aid:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEC4899))),
                    const SizedBox(height: 4),
                    Text(symptom.firstAid!, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                  if (symptom.followUpQuestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Follow-up Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                    const SizedBox(height: 8),
                    ...List.generate(symptom.followUpQuestions.length, (i) {
                      final q = symptom.followUpQuestions[i];
                      final a = symptom.followUpAnswers.length > i ? symptom.followUpAnswers[i] : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q: $q', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            if (a != null && a.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, left: 8),
                                child: Text('A: $a', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (symptom.followUpLogic != null && symptom.followUpLogic!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Triage Reasoning:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(symptom.followUpLogic!, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'AI-generated clinical logic. Not a replacement for professional medical advice.',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text('This will permanently remove this symptom log. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(symptomControllerProvider.notifier).deleteSymptom(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No logs found', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'The AI analysis provided is for educational purposes and should not replace professional medical advice. Always seek the advice of your physician for any health-related concerns.',
                  style: TextStyle(fontSize: 12, color: Colors.amber[900], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
