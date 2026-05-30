import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subs_tracker/models/brand.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/utils/color_utils.dart';
import 'package:subs_tracker/widgets/brand_logo.dart';

class SubsPie extends ConsumerStatefulWidget {
  const SubsPie({super.key});

  @override
  ConsumerState<SubsPie> createState() => _SubsPieState();
}

class _SubsPieState extends ConsumerState<SubsPie> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final slicesAsync = ref.watch(subsControllerProvider);

    return slicesAsync.when(
      error: (e, st) => Center(child: Text("common.error_generic".tr())),
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      data: (slices) => _buildChart(slices),
    );
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
                final label = s.brand?.text ?? s.name;
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
                    label: label,
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
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.borderColor, this.brand});
  final String label;
  final Color borderColor;
  final Brand? brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 25, minWidth: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), spreadRadius: -1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: brand != null ? BrandLogo(
          brand: brand,
          size: 25,
        ) :
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
      ),
    );
  }
}
