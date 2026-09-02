import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models/card-models.dart';
import 'widgets/card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon Battle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pokemon Battle Cards'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<PokemonData>>(
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
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            itemCount: pokemons.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return Center(
                child: SingleChildScrollView(
                  child: PokemonCard(data: pokemons[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
