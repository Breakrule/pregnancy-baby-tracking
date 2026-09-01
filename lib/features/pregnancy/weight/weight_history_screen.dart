import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/animated_item_list.dart';
import '../../../data/db/app_database.dart';
import '../../../data/providers.dart';
import '../../../domain/gestational/gestational_calculator.dart';
import '../../../domain/growth/iom_weight_gain.dart';

/// Sample weeks at which IOM reference polylines are evaluated.
const _sampleWeeks = [0, 14, 20, 28, 32, 36, 40];

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightsAsync = ref.watch(weightsStreamProvider);
    final pregnancyAsync = ref.watch(activePregnancyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/track/weight/new'),
          ),
        ],
      ),
      body: weightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => pregnancyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (pregnancy) => _buildBody(context, ref, entries, pregnancy),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<WeightEntry> entries,
    Pregnancy? pregnancy,
  ) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No weight entries yet.\nTap + to log your first weight.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Chart section
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
            child: _buildChart(
              entries,
              pregnancy,
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const Divider(height: 1),
        // Entries list — newest first, insert/remove animated.
        Expanded(
          child: AnimatedItemStream<WeightEntry>(
            padding: const EdgeInsets.symmetric(vertical: 8),
            items: entries.reversed.toList(),
            itemId: (entry) => entry.id,
            itemBuilder: (context, entry) =>
                _buildEntryTile(context, ref, entry),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    List<WeightEntry> entries,
    Pregnancy? pregnancy,
    Color primaryColor,
  ) {
    // Compute gestational week for each entry
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final entry in entries) {
      double x;
      if (pregnancy != null) {
        final ga = GestationalCalculator.gestationalAgeAt(
          pregnancy.lmpDate,
          entry.date,
        );
        x = ga.weeks.toDouble();
      } else {
        // Fallback: use index as x if no pregnancy
        x = spots.length.toDouble();
      }
      spots.add(FlSpot(x, entry.weightKg));
      if (entry.weightKg < minY) minY = entry.weightKg;
      if (entry.weightKg > maxY) maxY = entry.weightKg;
    }

    // Build IOM reference polylines if we have a pregnancy with pre-pregnancy weight
    final iomBars = <LineChartBarData>[];
    if (pregnancy != null) {
      final category = IomWeightGain.bmiCategory(
        pregnancy.prePregnancyWeightKg,
        pregnancy.heightCm,
      );
      final baseWeight = pregnancy.prePregnancyWeightKg;

      final minSpots = <FlSpot>[];
      final maxSpots = <FlSpot>[];
      for (final week in _sampleWeeks) {
        final range = IomWeightGain.expectedRangeAt(
          category,
          gestationalDay: week * 7,
        );
        minSpots.add(FlSpot(week.toDouble(), baseWeight + range.minKg));
        maxSpots.add(FlSpot(week.toDouble(), baseWeight + range.maxKg));

        final yMin = baseWeight + range.minKg;
        final yMax = baseWeight + range.maxKg;
        if (yMin < minY) minY = yMin;
        if (yMax > maxY) maxY = yMax;
      }

      iomBars.add(
        LineChartBarData(
          spots: minSpots,
          isCurved: false,
          color: Colors.green.withValues(alpha: 0.5),
          barWidth: 2,
          dashArray: [8, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
      iomBars.add(
        LineChartBarData(
          spots: maxSpots,
          isCurved: false,
          color: Colors.green.withValues(alpha: 0.5),
          barWidth: 2,
          dashArray: [8, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Add some padding to y-axis
    final yPadding = (maxY - minY) * 0.1;
    if (yPadding < 1) {
      minY -= 1;
      maxY += 1;
    } else {
      minY -= yPadding;
      maxY += yPadding;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}w',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Actual weight entries — solid line
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: primaryColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(radius: 3),
            ),
            belowBarData: BarAreaData(show: false),
          ),
          ...iomBars,
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} kg\nWeek ${spot.x.toInt()}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryTile(
    BuildContext context,
    WidgetRef ref,
    WeightEntry entry,
  ) {
    final dateFormat = DateFormat.yMMMd();
    final dateStr = dateFormat.format(entry.date.toLocal());

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade50,
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        ref.read(weightRepositoryProvider).delete(entry.id);
      },
      child: ListTile(
        title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
        subtitle: Text(
          '$dateStr${entry.notes != null ? '\n${entry.notes}' : ''}',
        ),
        leading: const Icon(Icons.scale_outlined),
      ),
    );
  }
}
