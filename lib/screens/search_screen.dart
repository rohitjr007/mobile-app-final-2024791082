import 'package:material_ui/material_ui.dart';

import '../models/meal.dart';
import '../services/api_service.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.apiService = const ApiService()});

  final ApiService apiService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _submittedQuery = '';
  Future<List<Meal>>? _results;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    if (_results != null && value.trim() != _submittedQuery) {
      setState(() {
        _submittedQuery = '';
        _results = null;
      });
    }
  }

  void _search(String input) {
    final query = input.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    final results = widget.apiService.fetchMealsByName(query);
    // A fast failure can arrive before FutureBuilder subscribes on the next frame.
    results.ignore();
    setState(() {
      _submittedQuery = query;
      _results = results;
    });
  }

  void _openMeal(String id) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            MealDetailScreen(mealId: id, apiService: widget.apiService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search recipes')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    onSubmitted: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Meal name',
                      hintText: 'For example, chicken',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        onPressed: () => _search(_controller.text),
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildResults()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _results;
    if (results == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Enter a meal name to find recipes.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return FutureBuilder<List<Meal>>(
      future: results,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Searching recipes',
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not search recipes.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _search(_submittedQuery),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final meals = snapshot.requireData;
        if (meals.isEmpty) {
          return const Center(child: Text('No recipes found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: meals.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final meal = meals[index];
            return MealCard(meal: meal, onTap: () => _openMeal(meal.id));
          },
        );
      },
    );
  }
}
