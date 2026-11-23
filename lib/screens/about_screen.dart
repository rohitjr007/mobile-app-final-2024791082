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
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ClipOval(
                        child: SizedBox.square(
                          dimension: 104,
                          child: Image.asset(
                            'assets/images/student_photo.jpeg',
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Student Photo'),
                      const SizedBox(height: 12),
                      const ListTile(
                        title: Text('Student Name'),
                        subtitle: Text('Sarina Karki'),
                      ),
                      const ListTile(
                        title: Text('Student ID'),
                        subtitle: Text('2024791082'),
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
