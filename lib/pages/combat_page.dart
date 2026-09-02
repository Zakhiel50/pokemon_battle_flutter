import 'package:flutter/material.dart';

import '../models/card-models.dart';
import 'combat/combat_initial_page.dart';

class CombatPage extends StatelessWidget {
  final List<PokemonData> deck;

  const CombatPage({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return CombatInitialPage(deck: deck);
  }
}
