import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: highlight ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (unit != null)
              Text(unit!, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
