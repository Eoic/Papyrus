import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:papyrus/models/genre_stats.dart';
import 'package:papyrus/themes/design_tokens.dart';

/// Chart displaying genre distribution as a donut chart with legend.
class GenreDistribution extends StatelessWidget {
  /// Genre statistics to display.
  final List<GenreStats> genres;

  /// Whether to use desktop styling.
  final bool isDesktop;

  const GenreDistribution({
    super.key,
    required this.genres,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return _buildEmptyState(context);
    return _buildChart(context);
  }

  // ============================================================================
  // DONUT CHART
  // ============================================================================

  Widget _buildChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartSize = isDesktop ? 200.0 : 150.0;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Books by genre', style: textTheme.titleMedium),
          const SizedBox(height: Spacing.md),
          // Chart and legend
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: chartSize,
                height: chartSize,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    genres: genres,
                    colors: _getChartColors(colorScheme),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.lg),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: genres.asMap().entries.map((entry) {
                    final index = entry.key;
                    final genre = entry.value;
                    return _buildLegendItem(
                      context,
                      color: _getChartColors(colorScheme)[index % 4],
                      label: genre.genre,
                      percentage: genre.percentageInt,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int percentage,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$percentage%',
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // EMPTY STATE
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Text(
          'No genre data available',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  List<Color> _getChartColors(ColorScheme colorScheme) {
    return [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      colorScheme.outline,
    ];
  }
}

/// Custom painter for donut chart.
class _DonutChartPainter extends CustomPainter {
  final List<GenreStats> genres;
  final List<Color> colors;

  _DonutChartPainter({required this.genres, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.35;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = -math.pi / 2; // Start from top

    for (var i = 0; i < genres.length; i++) {
      final genre = genres[i];
      final sweepAngle = 2 * math.pi * genre.percentage;

      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
