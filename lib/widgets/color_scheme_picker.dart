import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ColorSchemePicker extends StatelessWidget {
  const ColorSchemePicker({
    super.key,
    required this.selectedScheme,
    required this.onSchemeSelected,
  });

  final FlexScheme selectedScheme;
  final ValueChanged<FlexScheme> onSchemeSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: kCuratedSchemes.map(((FlexScheme, String) entry) {
          final (scheme, _) = entry;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ColorSchemeDot(
              scheme: scheme,
              isSelected: scheme == selectedScheme,
              onTap: () => onSchemeSelected(scheme),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ColorSchemeDot extends StatelessWidget {
  const ColorSchemeDot({
    super.key,
    required this.scheme,
    required this.isSelected,
    required this.onTap,
  });

  final FlexScheme scheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = FlexColor.schemes[scheme]!.light.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
