import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../models/sub_slice.dart';
import '../utils/color_utils.dart';
import 'brand_logo.dart';

class SubsPie extends StatefulWidget {
  const SubsPie({super.key, required this.slices});

  final List<SubSlice> slices;

  @override
  State<SubsPie> createState() => _SubsPieState();
}

class _SubsPieState extends State<SubsPie> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return _buildChart(widget.slices);
  }

  Widget _buildChart(List<SubSlice> slices) {
    final total = slices.fold<double>(0, (a, b) => a + b.monthlyAmount);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: PieChart(
            
            key: ValueKey(slices.hashCode),
            PieChartData(
              sectionsSpace: 5,
              centerSpaceRadius: 25,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    touchedIndex =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(slices.length, (i) {
                final s = slices[i];
                final isTouched = i == touchedIndex;
                final percent = total == 0 ? 0 : (s.monthlyAmount / total) * 100;
                return PieChartSectionData(
                  color: Color(s.color),
                  value: s.monthlyAmount,
                  title: '${percent.toStringAsFixed(2)}%',
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 16 : 13,
                    fontWeight: FontWeight.w800,
                    color: darkerOf(Color(s.color), 0.4),
                  ),
                  radius: isTouched ? 120 : 100,
                  badgeWidget: _Badge(
                    name: s.name,
                    brand: s.brand,
                    borderColor: Color(s.color),
                  ),
                  badgePositionPercentageOffset: 1.15,
                );
              }),
            ),
            duration: const Duration(milliseconds: 100),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.name, required this.borderColor, this.brand});
  final String name;
  final Color borderColor;
  final Brand? brand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), spreadRadius: -1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SubLeadingIcon(name: name, brand: brand, color: borderColor, size: 24),
      ),
    );
  }
}
