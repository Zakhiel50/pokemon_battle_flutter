import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/card-models.dart';

class PokemonApiService {
  static const String baseUrl = 'https://api.tcgdex.net/v2/fr/cards/swsh3-';

  /// Récupère les données d'un Pokémon selon son index (1 à 251)
  static Future<PokemonData?> fetchCard(int index) async {
    try {
      final url = Uri.parse('$baseUrl$index');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['category'] == 'Pokémon') {
          return PokemonData.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Récupère [count] cartes Pokémon aléatoires parmi les 251 de la série swsh3
  static Future<List<PokemonData>> fetchRandomPokemonCards(int count) async {
    final List<PokemonData> cards = [];
    final random = Random();
    final Set<int> usedIndices = {};

    int attempts = 0;
    while (cards.length < count && attempts < 30) {
      attempts++;
      final index = random.nextInt(201) + 1;
      if (usedIndices.contains(index)) continue;
      usedIndices.add(index);

      final card = await fetchCard(index);
      if (card != null && card.name.isNotEmpty) {
        cards.add(card);
      }
    }

    return cards;
  }
}
