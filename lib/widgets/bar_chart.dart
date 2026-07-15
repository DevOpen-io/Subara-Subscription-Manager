import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../models/sub_slice.dart';
import 'brand_logo.dart';

class SubsBar extends StatefulWidget {
  const SubsBar({
    super.key,
    required this.slices,
    required this.currency,
    this.multiplier = 1.0,
  });

  final List<SubSlice> slices;
  final String currency;
  final double multiplier;

  @override
  State<SubsBar> createState() => _SubsBarState();
}

class _SubsBarState extends State<SubsBar> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return _buildChart(widget.slices, widget.currency, widget.multiplier);
  }

  Widget _buildChart(List<SubSlice> slices, String currency, double multiplier) {
    if (slices.isEmpty) return const SizedBox.shrink();

    final maxY = slices.fold<double>(0, (a, b) => a > b.monthlyAmount ? a : b.monthlyAmount) * multiplier;

    return AspectRatio(
      aspectRatio: 1.2,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.25,
          barGroups: List.generate(slices.length, (i) {
            final s = slices[i];
            final isTouched = i == touchedIndex;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: s.monthlyAmount * multiplier,
                  color: Color(s.color),
                  width: isTouched ? 22 : 16,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
              showingTooltipIndicators: isTouched ? [0] : [],
            );
          }),
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              setState(() {
                touchedIndex = response?.spot?.touchedBarGroupIndex;
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '$currency${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == 0) return const SizedBox.shrink();
                  return Text(
                    '$currency${value.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= slices.length) return const SizedBox.shrink();
                  final s = slices[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _BarBadge(
                      name: s.name,
                      brand: s.brand,
                      color: Color(s.color),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _BarBadge extends StatelessWidget {
  const _BarBadge({required this.name, required this.color, this.brand});
  final String name;
  final Color color;
  final Brand? brand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SubLeadingIcon(name: name, brand: brand, color: color, size: 18),
      ),
    );
  }
}
