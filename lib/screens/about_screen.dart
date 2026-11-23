import 'package:material_ui/material_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Recipe Explorer', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(
                  'Browse recipe categories, search for meals, and save your favorites. '
                  'Recipes from TheMealDB include ingredients and cooking instructions.',
                ),
                const SizedBox(height: 24),
                const Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Student Name'),
                        subtitle: Text('Student name placeholder'),
                      ),
                      ListTile(
                        title: Text('Student ID'),
                        subtitle: Text('Student ID placeholder'),
                      ),
                      ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Student Photo'),
                        subtitle: Text('Student photo placeholder'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
