// lib/screens/ai_statistics_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/deck_provider.dart';

class AIStatisticsPage extends StatefulWidget {
  final ApiService api;
  final int deckId;

  const AIStatisticsPage({
    Key? key,
    required this.api,
    required this.deckId,
  }) : super(key: key);

  @override
  State<AIStatisticsPage> createState() => _AIStatisticsPageState();
}

class _AIStatisticsPageState extends State<AIStatisticsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _aiData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAIStatistics();
  }

  Future<void> _loadAIStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.api.getDeckAIPredictions(widget.deckId);

      if (mounted) {
        setState(() {
          _aiData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAIStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAIStatistics,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _buildStatistics(),
    );
  }

  Widget _buildStatistics() {
    if (_aiData == null) return const SizedBox.shrink();

    final stats = _aiData!['statistics'] as Map<String, dynamic>;
    final predictions = _aiData!['predictions'] as Map<String, dynamic>;

    final totalCards = stats['total_cards'] ?? 0;
    final highRisk = stats['high_risk_cards'] ?? 0;
    final mediumRisk = stats['medium_risk_cards'] ?? 0;
    final lowRisk = stats['low_risk_cards'] ?? 0;
    final avgForgetting = stats['average_forgetting_probability'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'AI Analysis Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalCards cards analyzed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Avg. Forgetting Risk:',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${avgForgetting.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Risk Distribution
          const Text(
            'Risk Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildRiskCard(
            'High Risk',
            highRisk,
            totalCards,
            Colors.red,
            Icons.warning_rounded,
            '≥70% forgetting probability',
          ),
          const SizedBox(height: 12),

          _buildRiskCard(
            'Medium Risk',
            mediumRisk,
            totalCards,
            Colors.orange,
            Icons.info_rounded,
            '40-69% forgetting probability',
          ),
          const SizedBox(height: 12),

          _buildRiskCard(
            'Low Risk',
            lowRisk,
            totalCards,
            Colors.green,
            Icons.check_circle_rounded,
            '<40% forgetting probability',
          ),

          const SizedBox(height: 24),

          // Card Details
          const Text(
            'Individual Card Predictions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ...predictions.entries.map((entry) {
            final cardId = entry.key;
            final prediction = entry.value as Map<String, dynamic>;
            return _buildCardPredictionTile(cardId, prediction);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRiskCard(
      String title,
      int count,
      int total,
      Color color,
      IconData icon,
      String description,
      ) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: count / (total > 0 ? total : 1),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardPredictionTile(String cardId, Map<String, dynamic> prediction) {
    final forgettingProb = prediction['forgetting_probability'] ?? 0;
    final difficulty = prediction['difficulty'] ?? 'Medium';
    final recommendedInterval = prediction['recommended_interval'] ?? 1;
    final reasoning = prediction['reasoning'] ?? '';
    final confidence = prediction['confidence'] ?? 0;

    Color riskColor;
    IconData riskIcon;

    if (forgettingProb >= 70) {
      riskColor = Colors.red;
      riskIcon = Icons.warning_rounded;
    } else if (forgettingProb >= 40) {
      riskColor = Colors.orange;
      riskIcon = Icons.info_rounded;
    } else {
      riskColor = Colors.green;
      riskIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(riskIcon, color: riskColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Card #$cardId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$forgettingProb%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Difficulty: $difficulty • Next review: $recommendedInterval days',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailChip(
                        icon: Icons.psychology_rounded,
                        label: 'Confidence',
                        value: '$confidence%',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Interval',
                        value: '$recommendedInterval d',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                if (reasoning.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reasoning,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}