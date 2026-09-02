import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

import '../../models/card-models.dart';
import '../../services/pokemon_api_service.dart';
import '../../widgets/card.dart';

class BoosterOpeningPage extends StatefulWidget {
  final int cardCount;
  final String title;
  final Function(List<PokemonData> wonCards)? onBoosterOpened;

  const BoosterOpeningPage({
    super.key,
    this.cardCount = 2,
    this.title = 'Booster Pokémon',
    this.onBoosterOpened,
  });

  @override
  State<BoosterOpeningPage> createState() => _BoosterOpeningPageState();
}

class _BoosterOpeningPageState extends State<BoosterOpeningPage> {
  double _tearProgress = 0.0;
  bool _isOpened = false;
  List<PokemonData> _wonCards = [];
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadBoosterCards();
  }

  Future<void> _loadBoosterCards() async {
    List<PokemonData> apiCards =
        await PokemonApiService.fetchRandomPokemonCards(widget.cardCount);

    if (apiCards.length < widget.cardCount) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/pokemon-data.json',
        );
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final localPokemons = jsonList
            .map((json) => PokemonData.fromJson(json as Map<String, dynamic>))
            .toList();

        localPokemons.shuffle();
        while (apiCards.length < widget.cardCount && localPokemons.isNotEmpty) {
          apiCards.add(localPokemons.removeLast());
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _wonCards = apiCards;
        _isLoadingCards = false;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isOpened) return;

    setState(() {
      _tearProgress += details.primaryDelta! / 180.0;
      _tearProgress = _tearProgress.clamp(0.0, 1.0);

      if (_tearProgress >= 0.85 && !_isOpened) {
        _isOpened = true;
        _tearProgress = 1.0;

        if (widget.onBoosterOpened != null) {
          widget.onBoosterOpened!(_wonCards);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoadingCards
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text(
                    'Chargement en cours...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              )
            : !_isOpened
            ? _buildBoosterTearView()
            : _buildCardsRevealedView(),
      ),
    );
  }

  Widget _buildBoosterTearView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Déchirez le haut du booster !',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.touch_app, color: Colors.amber, size: 20),
            SizedBox(width: 6),
            Text(
              'Glissez votre doigt de gauche à droite sur les pointillés',
              style: TextStyle(color: Colors.amberAccent, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Le Booster Pack Interactif
        SizedBox(
          width: 260,
          height: 380,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // CORPS DU BOOSTER
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB71C1C),
                        Color(0xFFE53935),
                        Color(0xFFFF8A80),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.amber, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.amberAccent,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.amber,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BOOSTER SWSH3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.cardCount} CARTES POKÉMON',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // HAUT DU BOOSTER (À DÉCHIRER AVEC TILT)
              Positioned(
                top: -_tearProgress * 40,
                left: _tearProgress * 80,
                right: -_tearProgress * 80,
                height: 65,
                child: Transform.rotate(
                  angle: _tearProgress * 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cut, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '- - - DÉCHIRER ICI - - -',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ZONE TACTILE POUR DÉCHIRER LE HAUT
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 90,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _tearProgress,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_tearProgress * 100).toInt()}% Déchiré',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardsRevealedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Félicitations ! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vous avez obtenu ${widget.cardCount} cartes Pokémon :',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 24),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _wonCards.map((card) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      PokemonCard(data: card, width: 130),
                      const SizedBox(height: 8),
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 36),

          ElevatedButton.icon(
            onPressed: () => context.go('/cards'),
            icon: const Icon(Icons.style),
            label: const Text('Ajouter à ma collection & Voir mes cartes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
