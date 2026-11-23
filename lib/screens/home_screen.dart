import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import '../services/favorites_controller.dart';
import '../widgets/category_card.dart';
import 'meal_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.apiService = const ApiService(),
    this.favorites,
    this.embedded = false,
  });

  final ApiService apiService;
  final FavoritesController? favorites;
  final bool embedded;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() {
    final categories = widget.apiService.fetchCategories();
    // FutureBuilder subscribes during the next build.
    categories.ignore();
    return categories;
  }

  void _retry() {
    setState(() {
      _categories = _fetchCategories();
    });
  }

  void _onCategoryTap(Category category) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MealListScreen(
          categoryName: category.name,
          apiService: widget.apiService,
          favorites: widget.favorites,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelSize = Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;
    final labelHeight =
        MediaQuery.textScalerOf(context).scale(labelSize) * 1.25;
    final body = SafeArea(
      child: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading recipe categories',
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
                      'Could not load recipe categories.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final categories = snapshot.requireData;
          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No recipe categories are available.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 124 + labelHeight * 2,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    category: category,
                    onTap: () => _onCategoryTap(category),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Explorer')),
      body: body,
    );
  }
}
