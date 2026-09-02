import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/card-models.dart';
import '../widgets/card.dart';

class CardsPage extends StatefulWidget {
  final List<PokemonData> deck;
  final VoidCallback? onDeckChanged;

  const CardsPage({super.key, required this.deck, this.onDeckChanged});

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

  void _notifyDeckChanged() {
    setState(() {});
    if (widget.onDeckChanged != null) {
      widget.onDeckChanged!();
    }
  }

  void _onCardTapped(PokemonData pokemon) {
    final isAlreadyInDeck = widget.deck.any((c) => c.name == pokemon.name);

    if (isAlreadyInDeck) {
      widget.deck.removeWhere((c) => c.name == pokemon.name);
      _notifyDeckChanged();
    } else {
      if (widget.deck.length < 3) {
        widget.deck.add(pokemon);
        _notifyDeckChanged();
      } else {
        // Deck plein (3/3) -> ouvrir la modale de remplacement
        _showReplacementModal(pokemon);
      }
    }
  }

  void _showReplacementModal(PokemonData newPokemon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade900,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre deck est plein (3/3)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Pour ajouter "${newPokemon.name}", cliquez sur la carte que vous souhaitez retirer de votre deck :',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.deck.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cardInDeck = widget.deck[index];
                    return GestureDetector(
                      onTap: () {
                        widget.deck[index] = newPokemon;
                        _notifyDeckChanged();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${cardInDeck.name} a été remplacé par ${newPokemon.name} !',
                            ),
                            backgroundColor: Colors.green.shade700,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                PokemonCard(data: cardInDeck, width: 140),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: CircleAvatar(
                                        backgroundColor: Colors.red,
                                        child: Icon(
                                          Icons.swap_horiz,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cardInDeck.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Annuler l\'ajout'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeckModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mon Deck (${widget.deck.length}/3)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  if (widget.deck.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'Votre deck est actuellement vide.\nCliquez sur des cartes pour les ajouter (3 max).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  else
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.deck.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final card = widget.deck[index];
                          return Column(
                            children: [
                              Expanded(
                                child: PokemonCard(data: card, width: 140),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  widget.deck.removeAt(index);
                                  _notifyDeckChanged();
                                  setModalState(() {});
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Retirer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade800,
                                  elevation: 0,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            scrollDirection: Axis.vertical,
            itemCount: pokemons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pokemon = pokemons[index];
              final isSelected = widget.deck.any((c) => c.name == pokemon.name);

              return Center(
                child: PokemonCard(
                  data: pokemon,
                  isSelected: isSelected,
                  onTap: () => _onCardTapped(pokemon),
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDeckModal,
        icon: const Icon(Icons.style),
        label: Text('Voir mon deck (${widget.deck.length}/3)'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
