import 'package:material_ui/material_ui.dart';

import '../models/meal.dart';
import '../services/api_service.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

class MealListScreen extends StatefulWidget {
  const MealListScreen({
    super.key,
    required this.categoryName,
    this.apiService = const ApiService(),
  });

  final String categoryName;
  final ApiService apiService;

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  late Future<List<Meal>> _meals;

  @override
  void initState() {
    super.initState();
    _meals = _fetchMeals();
  }

  Future<List<Meal>> _fetchMeals() {
    return widget.apiService.fetchMealsByCategory(widget.categoryName);
  }

  void _retry() {
    setState(() {
      _meals = _fetchMeals();
    });
  }

  void _onMealTap(String mealId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            MealDetailScreen(mealId: mealId, apiService: widget.apiService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: SafeArea(
        child: FutureBuilder<List<Meal>>(
          future: _meals,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading meals',
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
                        'Could not load meals.',
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

            final meals = snapshot.requireData;
            if (meals.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No meals are available in this category.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return MealCard(
                      meal: meal,
                      onTap: () => _onMealTap(meal.id),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
