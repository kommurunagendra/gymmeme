import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router/app_router.dart';
import '../features/feed/screens/feed_screen.dart';
import '../features/meme_creator/screens/template_grid_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';

// Current tab index
final _tabIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Sign in anonymously on first launch
    await ref.read(authServiceProvider).signInAnonymously();
    // Pre-load interstitial
    adServiceInstance.loadInterstitial();
  }

  static const _tabs = [
    FeedScreen(),
    TemplateGridScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(_tabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) =>
            ref.read(_tabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_photo_alternate_outlined),
            selectedIcon: Icon(Icons.add_photo_alternate),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'My GymType',
          ),
        ],
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.dailyLog),
              icon: const Icon(Icons.add),
              label: const Text('Log Session'),
            )
          : null,
    );
  }
}
