import 'package:material_ui/material_ui.dart';

import '../models/meal.dart';
import '../services/api_service.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({
    super.key,
    required this.mealId,
    this.apiService = const ApiService(),
  });

  final String mealId;
  final ApiService apiService;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late Future<Meal?> _meal;

  @override
  void initState() {
    super.initState();
    _meal = widget.apiService.fetchMealDetails(widget.mealId);
  }

  void _retry() {
    setState(() {
      _meal = widget.apiService.fetchMealDetails(widget.mealId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal details')),
      body: SafeArea(
        child: FutureBuilder<Meal?>(
          future: _meal,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading meal details',
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load meal details.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final meal = snapshot.data;
            if (meal == null) {
              return const Center(child: Text('Meal not found.'));
            }
            return _MealContent(meal: meal);
          },
        ),
      ),
    );
  }
}

class _MealContent extends StatelessWidget {
  const _MealContent({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = meal.thumbnailUrl;
    final imagePlaceholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.restaurant_outlined,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: thumbnailUrl == null
                    ? imagePlaceholder
                    : Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) =>
                            imagePlaceholder,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(meal.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Category: ${meal.category ?? 'Not specified'}'),
            Text('Area: ${meal.area ?? 'Not specified'}'),
            const SizedBox(height: 24),
            Text('Ingredients', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (meal.ingredients.isEmpty) const Text('No ingredients listed.'),
            for (final ingredient in meal.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(ingredient.name)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        ingredient.measure ?? 'Not specified',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text('Instructions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              meal.instructions ?? 'No cooking instructions available.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
