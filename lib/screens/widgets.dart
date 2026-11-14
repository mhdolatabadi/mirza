import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter/material.dart';

import '../services/format.dart';
import '../services/ledger.dart';
import '../theme.dart';

/// Category icon in a tinted rounded square.
class CategoryBadge extends StatelessWidget {
  final String category;
  final double size;
  const CategoryBadge(this.category, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = MirzaColors.of(context).categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
      child: Icon(categoryIcon(category), color: color, size: size * 0.52),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Ledger ledger;
  final MoneyUnit unit;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.ledger,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final theme = Theme.of(context);
    final credit = t.type == TransactionType.credit;
    final category = ledger.categoryOf(t);
    final description = t.description?.trim();
    final subtitle = [ledger.bankLabel(t), if (t.time != null) faDigits(t.time!)].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CategoryBadge(category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description == null || description.isEmpty || description == category
                        ? category
                        : '$category · $description',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(t.signedAmount, unit, signed: true),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: credit ? MirzaColors.of(context).income : theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(unitLabel(unit), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of month chips; the selected one is saffron.
class MonthChips extends StatelessWidget {
  final List<(int, int)> months;
  final int selected;
  final ValueChanged<int> onSelected;

  const MonthChips({super.key, required this.months, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colors = MirzaColors.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: months.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (y, m) = months[i];
          final on = i == selected;
          return ChoiceChip(
            label: Text(monthTitle(y, m)),
            selected: on,
            selectedColor: colors.saffron,
            labelStyle: TextStyle(
              fontFamily: 'Vazirmatn',
              color: on ? colors.onSaffron : Theme.of(context).colorScheme.onSurface,
              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
            ),
            side: on ? BorderSide(color: colors.saffron) : null,
            onSelected: (_) => onSelected(i),
          );
        },
      ),
    );
  }
}

/// Centered message for empty and error states.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
