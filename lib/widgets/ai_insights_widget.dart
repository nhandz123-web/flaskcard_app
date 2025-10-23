// Widget để hiển thị AI insights
// lib/widgets/ai_insights_widget.dart

import 'package:flutter/material.dart';

class AIInsightsWidget extends StatelessWidget {
  final Map<String, dynamic>? prediction;
  final bool isLoading;

  const AIInsightsWidget({
    Key? key,
    this.prediction,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'AI đang phân tích...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (prediction == null) return const SizedBox.shrink();

    // Null-safe extraction với kiểm tra type
    final dynamic forgettingProbDynamic = prediction!['forgetting_probability'];
    final dynamic difficultyDynamic = prediction!['difficulty'];
    final dynamic reasoningDynamic = prediction!['reasoning'];
    final dynamic confidenceDynamic = prediction!['confidence'];
    final dynamic aiPoweredDynamic = prediction!['ai_powered'];

    // Convert sang type cụ thể
    final int forgettingProb = (forgettingProbDynamic is int)
        ? forgettingProbDynamic
        : (forgettingProbDynamic is double)
        ? forgettingProbDynamic.toInt()
        : 0;

    final String difficulty = (difficultyDynamic is String)
        ? difficultyDynamic
        : 'Medium';

    final String reasoning = (reasoningDynamic is String)
        ? reasoningDynamic
        : '';

    final int confidence = (confidenceDynamic is int)
        ? confidenceDynamic
        : (confidenceDynamic is double)
        ? confidenceDynamic.toInt()
        : 0;

    final bool aiPowered = (aiPoweredDynamic is bool)
        ? aiPoweredDynamic
        : false;

    // Màu sắc dựa trên khả năng quên
    Color probabilityColor;
    IconData probabilityIcon;
    String probabilityText;

    if (forgettingProb >= 70) {
      probabilityColor = Colors.red;
      probabilityIcon = Icons.warning_rounded;
      probabilityText = 'Nguy cơ quên cao';
    } else if (forgettingProb >= 40) {
      probabilityColor = Colors.orange;
      probabilityIcon = Icons.info_rounded;
      probabilityText = 'Nguy cơ quên trung bình';
    } else {
      probabilityColor = Colors.green;
      probabilityIcon = Icons.check_circle_rounded;
      probabilityText = 'Nguy cơ quên thấp';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            probabilityColor.withOpacity(0.1),
            probabilityColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: probabilityColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với AI badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: aiPowered ? Colors.purple.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      aiPowered ? Icons.auto_awesome : Icons.calculate,
                      size: 14,
                      color: aiPowered ? Colors.purple.shade700 : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      aiPowered ? 'AI Insights' : 'SM-2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: aiPowered ? Colors.purple.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: probabilityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$forgettingProb%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: probabilityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Probability indicator
          Row(
            children: [
              Icon(probabilityIcon, color: probabilityColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      probabilityText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: probabilityColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: forgettingProb / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(probabilityColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Difficulty & Confidence
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.trending_up_rounded,
                  label: 'Độ khó',
                  value: difficulty,
                  color: difficulty == 'Hard'
                      ? Colors.red
                      : difficulty == 'Easy'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.psychology_rounded,
                  label: 'Độ tin cậy',
                  value: '$confidence%',
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
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
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}