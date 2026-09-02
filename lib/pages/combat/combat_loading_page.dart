import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/card-models.dart';
import '../../widgets/card.dart';

class CombatLoadingPage extends StatefulWidget {
  final List<PokemonData> deck;

  const CombatLoadingPage({super.key, required this.deck});

  @override
  State<CombatLoadingPage> createState() => _CombatLoadingPageState();
}

class _CombatLoadingPageState extends State<CombatLoadingPage> {
  int _countdownSeconds = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          // Deep navigation vers l'arène avec le deck transmis via .extra
          context.pushReplacement('/combat/arena', extra: widget.deck);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préparation du Duel'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Préparation du Duel...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Alignement des 3 cartes du Deck dans $_countdownSeconds s',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Rendu visuel de la pile de 3 cartes empilées
              SizedBox(
                height: 250,
                width: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(widget.deck.length, (index) {
                    final reverseIndex = widget.deck.length - 1 - index;
                    final offsetTop = reverseIndex * 14.0;
                    final offsetLeft = reverseIndex * 14.0;
                    final scale = 1.0 - (reverseIndex * 0.04);

                    return Positioned(
                      top: offsetTop,
                      left: offsetLeft,
                      child: Transform.scale(
                        scale: scale,
                        child: PokemonCard(
                          data: widget.deck[index],
                          width: 160,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.red.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
