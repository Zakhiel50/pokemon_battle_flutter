import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/card-models.dart';
import 'pages/cards_page.dart';
import 'pages/combat/combat_arena_page.dart';
import 'pages/combat/combat_initial_page.dart';
import 'pages/combat/combat_loading_page.dart';

void main() {
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<PokemonData> _deck = [];

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/cards',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          int currentIndex = 0;
          if (state.matchedLocation.startsWith('/combat')) {
            currentIndex = 1;
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(
                currentIndex == 0 ? 'Mes cartes Pokémon' : 'Arène de Combat',
              ),
              centerTitle: true,
            ),
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index == 0) {
                  context.go('/cards');
                } else {
                  context.go('/combat');
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style),
                  label: 'Mes cartes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_outlined),
                  selectedIcon: Icon(Icons.sports_esports),
                  label: 'Combat',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/cards',
            builder: (context, state) =>
                CardsPage(deck: _deck, onDeckChanged: () => setState(() {})),
          ),
          GoRoute(
            path: '/combat',
            builder: (context, state) => CombatInitialPage(deck: _deck),
          ),
        ],
      ),
      GoRoute(
        path: '/combat/loading',
        builder: (context, state) {
          final deck = state.extra as List<PokemonData>;
          return CombatLoadingPage(deck: deck);
        },
      ),
      GoRoute(
        path: '/combat/arena',
        builder: (context, state) {
          final deck = state.extra as List<PokemonData>;
          return CombatArenaPage(playerDeck: deck);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pokemon Battle',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
