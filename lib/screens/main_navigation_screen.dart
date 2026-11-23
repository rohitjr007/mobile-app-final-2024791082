import 'package:material_ui/material_ui.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.apiService = const ApiService()});

  final ApiService apiService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const _titles = ['Recipe Explorer', 'Search recipes', 'Favorites'];
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (index == _selectedIndex) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(apiService: widget.apiService, embedded: true),
      SearchScreen(apiService: widget.apiService, embedded: true),
      const Center(child: Text('Favorites are coming soon.')),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(
        index: _selectedIndex,
        sizing: StackFit.expand,
        children: [
          for (var index = 0; index < tabs.length; index++)
            ExcludeFocus(
              excluding: index != _selectedIndex,
              child: TickerMode(
                enabled: index == _selectedIndex,
                child: tabs[index],
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
