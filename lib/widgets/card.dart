import 'package:flutter/material.dart';
import 'package:pokemon_battle/widgets/stats-card.dart';

import 'header-card.dart';
import 'body-card.dart';
import '../models/card-models.dart';

class PokemonCard extends StatelessWidget {
  final PokemonData data;

  const PokemonCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Colors.yellow.shade100, // Couleur de fond selon le type idéalement
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 8,
        ), // Bordure classique
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokemonCardHeader(name: data.name, hp: data.hp, type: data.type),
          PokemonCardBody(imageUrl: data.imageUrl),

          // Liste des attaques
          ...data.attacks
              .map((attack) => PokemonAttackItem(attack: attack))
              .toList(),

          // Petit footer classique des cartes
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: StatsCard(
              weakness: data.weakness,
              resistance: data.resistance,
              retreatCost: data.retreatCost,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Illus. Ken Sugimori'),
          ),
        ],
      ),
    );
  }
}
