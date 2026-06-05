import 'package:flutter/material.dart';
import 'package:subs_tracker/models/brand.dart';
import 'package:subs_tracker/utils/brand_utils.dart';

class SubLeadingIcon extends StatelessWidget {
  const SubLeadingIcon({
    super.key,
    required this.name,
    required this.color,
    this.brand,
    required this.size,
  });

  final String name;
  final Color color;
  final Brand? brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (brand != null) return BrandLogo(brand: brand, size: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.15),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 32,
  });

  final Brand? brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconData = brand?.iconData;

    if (iconData != null) {
      final color = brand!.iconColor ?? Theme.of(context).colorScheme.onSurface;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: Center(
          child: Icon(iconData, size: size * 0.65, color: color),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Icon(
          Icons.subscriptions_outlined,
          size: size * 0.55,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
