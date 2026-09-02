import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/card-models.dart';
import '../widgets/card.dart';

class CardsPage extends StatefulWidget {
  final List<PokemonData> myCards;
  final List<PokemonData> deck;
  final VoidCallback? onDeckChanged;

  const CardsPage({
    super.key,
    required this.myCards,
    required this.deck,
    this.onDeckChanged,
  });

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
    if (widget.myCards.isNotEmpty) {
      return widget.myCards;
    }

    final String jsonString = await rootBundle.loadString(
      'assets/pokemon-data.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);
    final initialCards = jsonList
        .map((json) => PokemonData.fromJson(json as Map<String, dynamic>))
        .toList();

    widget.myCards.addAll(initialCards);
    return widget.myCards;
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
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.deck.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final cardInDeck = widget.deck[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.deck.removeAt(index);
                          widget.deck.add(newPokemon);
                        });
                        _notifyDeckChanged();
                        Navigator.pop(context);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PokemonCard(data: cardInDeck, width: 140),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 20,
                              ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  void _showDeckViewerModal() {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.style, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            'Mon Deck (${widget.deck.length}/3)',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.deck.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'Aucune carte dans votre deck.\nCliquez sur les cartes de votre collection pour constituer votre deck.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.deck.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final cardInDeck = widget.deck[index];
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              PokemonCard(data: cardInDeck, width: 140),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      widget.deck.removeAt(index);
                                    });
                                    _notifyDeckChanged();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Fermer le deck',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erreur de chargement des cartes.'),
            );
          }

          final pokemons = snapshot.data!;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.amber.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collection (${pokemons.length} cartes)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    Text(
                      'Deck : ${widget.deck.length} / 3',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.deck.length == 3
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const ClampingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: pokemons.length,
                  itemBuilder: (context, index) {
                    final pokemon = pokemons[index];
                    final isSelectedInDeck =
                        widget.deck.any((c) => c.name == pokemon.name);

                    return PokemonCard(
                      data: pokemon,
                      isSelected: isSelectedInDeck,
                      onTap: () => _onCardTapped(pokemon),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _showDeckViewerModal,
            icon: const Icon(Icons.style),
            label: Text(
              'Voir mon deck (${widget.deck.length}/3)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
