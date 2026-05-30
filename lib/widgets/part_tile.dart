import 'dart:io';
import 'package:flutter/material.dart';
import '../models/part.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PartTile extends StatelessWidget {
  final Part part;
  final VoidCallback onTap;
  const PartTile({super.key, required this.part, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color stockColor = AppTheme.success;
    String stockLabel = 'In stock';
    if (part.isOutOfStock) {
      stockColor = AppTheme.danger;
      stockLabel = 'Out of stock';
    } else if (part.isLowStock) {
      stockColor = AppTheme.warning;
      stockLabel = 'Low stock';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _thumb(cs),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                        '${part.brand} • ${part.partNumber}'
                        '${part.vehicleModel != null ? ' • ${part.vehicleModel}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurface.withOpacity(.6))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip(part.category, cs.primary.withOpacity(.12),
                            cs.primary),
                        const SizedBox(width: 6),
                        if (part.partType == PartType.oem) ...[
                          _chip('OEM', AppTheme.secondary.withOpacity(.15),
                              AppTheme.secondary),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: stockColor.withOpacity(.14),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.circle, size: 8, color: stockColor),
                            const SizedBox(width: 4),
                            Text(stockLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: stockColor,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.money(part.sellingPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${part.quantity} ${part.unit}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: stockColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(ColorScheme cs) {
    if (part.imagePath != null && File(part.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(part.imagePath!),
            width: 54, height: 54, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(14)),
      child: Icon(iconFor(part.category), color: Colors.white, size: 26),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
      );

  static IconData iconFor(String category) => switch (category) {
        'Brakes' => Icons.disc_full,
        'Filters' => Icons.filter_alt,
        'Battery' => Icons.battery_charging_full,
        'Tyres' => Icons.tire_repair,
        'Engine' => Icons.settings,
        'Electrical' => Icons.electrical_services,
        'Lighting' => Icons.lightbulb,
        'Suspension' => Icons.compress,
        'Lubricants & Fluids' => Icons.water_drop,
        'Ignition' => Icons.flash_on,
        'Cooling' => Icons.ac_unit,
        'Wipers' => Icons.cleaning_services,
        'Steering' => Icons.trip_origin,
        'Bearings' => Icons.donut_large,
        'Exhaust' => Icons.air,
        _ => Icons.build,
      };
}
