import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/card-models.dart';
import '../widgets/card.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late Future<List<PokemonData>> _pokemonListFuture;

  @override
  void initState() {
    super.initState();
    _pokemonListFuture = _loadPokemonData();
  }

  Future<List<PokemonData>> _loadPokemonData() async {
    final String jsonString = await rootBundle.loadString(
      'assets/pokemon-data.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => PokemonData.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PokemonData>>(
      future: _pokemonListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Erreur de chargement: ${snapshot.error}'),
            ),
          );
        }
        final pokemons = snapshot.data ?? [];
        if (pokemons.isEmpty) {
          return const Center(child: Text('Aucun Pokémon trouvé.'));
        }

        return ListView.separated(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          scrollDirection: Axis.vertical,
          itemCount: pokemons.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return Center(
              child: PokemonCard(data: pokemons[index]),
            );
          },
        );
      },
    );
  }
}
