import 'package:material_ui/material_ui.dart';

import '../models/meal.dart';

class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.meal, required this.onTap});

  final Meal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = meal.thumbnailUrl;
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.restaurant_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 56,
                  child: thumbnailUrl == null
                      ? placeholder
                      : Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (context, error, stackTrace) =>
                              placeholder,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(meal.name, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
