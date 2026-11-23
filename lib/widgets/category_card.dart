import 'package:material_ui/material_ui.dart';

import '../models/category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: SizedBox.expand(
                    child: Image.network(
                      category.thumbnailUrl,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  category.name,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onTap),
          ),
        ],
      ),
    );
  }
}
