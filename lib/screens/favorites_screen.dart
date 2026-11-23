import 'package:material_ui/material_ui.dart';

import '../models/meal.dart';
import '../services/api_service.dart';
import '../services/favorites_controller.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.favorites,
    this.apiService = const ApiService(),
  });

  final FavoritesController favorites;
  final ApiService apiService;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: favorites,
        builder: (context, child) {
          if (favorites.loading) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading favorites',
              ),
            );
          }
          if (favorites.loadFailed) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not load saved favorites.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: favorites.load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final ids = favorites.mealIds;
          if (ids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No favorites yet.', textAlign: TextAlign.center),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ids.length,
                findChildIndexCallback: (key) {
                  final index = ids.indexOf((key as ValueKey<String>).value);
                  return index < 0 ? null : index;
                },
                itemBuilder: (context, index) {
                  final id = ids[index];
                  return Padding(
                    key: ValueKey(id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SavedMeal(
                      mealId: id,
                      favorites: favorites,
                      apiService: apiService,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SavedMeal extends StatefulWidget {
  const _SavedMeal({
    required this.mealId,
    required this.favorites,
    required this.apiService,
  });

  final String mealId;
  final FavoritesController favorites;
  final ApiService apiService;

  @override
  State<_SavedMeal> createState() => _SavedMealState();
}

class _SavedMealState extends State<_SavedMeal> {
  late Future<Meal?> _meal;

  @override
  void initState() {
    super.initState();
    _meal = _fetchMeal();
  }

  Future<Meal?> _fetchMeal() {
    final meal = widget.apiService.fetchMealDetails(widget.mealId);
    meal.ignore();
    return meal;
  }

  void _retry() {
    setState(() {
      _meal = _fetchMeal();
    });
  }

  void _openMeal() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MealDetailScreen(
          mealId: widget.mealId,
          apiService: widget.apiService,
          favorites: widget.favorites,
        ),
      ),
    );
  }

  Future<void> _removeUnavailableMeal() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await widget.favorites.toggle(widget.mealId) && messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update favorites.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Meal?>(
      future: _meal,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading saved meal',
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return ListTile(
            title: const Text('Could not load a saved meal.'),
            trailing: TextButton(onPressed: _retry, child: const Text('Retry')),
          );
        }
        final meal = snapshot.data;
        if (meal == null) {
          return ListTile(
            title: const Text('Saved meal no longer available.'),
            trailing: TextButton(
              onPressed: widget.favorites.canEdit
                  ? _removeUnavailableMeal
                  : null,
              child: const Text('Remove'),
            ),
          );
        }
        return MealCard(meal: meal, onTap: _openMeal);
      },
    );
  }
}
