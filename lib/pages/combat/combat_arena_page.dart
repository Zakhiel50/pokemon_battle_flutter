import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

import '../../models/card-models.dart';
import '../../widgets/card.dart';

class CombatArenaPage extends StatefulWidget {
  final List<PokemonData> playerDeck;

  const CombatArenaPage({super.key, required this.playerDeck});

  @override
  State<CombatArenaPage> createState() => _CombatArenaPageState();
}

class _CombatArenaPageState extends State<CombatArenaPage> {
  List<PokemonData> _opponentDeck = [];
  int _opponentActiveIndex = 0;
  int _opponentHp = 0;
  int _maxOpponentHp = 0;

  int _playerActiveIndex = 0;
  int _playerHp = 0;
  int _maxPlayerHp = 0;

  String _battleLog = 'Duel 3v3 engagé !';
  bool _isAttacking = false;
  bool _isFinished = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpponentDeckAndStart();
  }

  Future<void> _loadOpponentDeckAndStart() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/pokemon-data.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final allPokemons = jsonList
          .map((json) => PokemonData.fromJson(json as Map<String, dynamic>))
          .toList();

      if (allPokemons.length >= 3) {
        _opponentDeck = [
          allPokemons[1 % allPokemons.length],
          allPokemons[3 % allPokemons.length],
          allPokemons[4 % allPokemons.length],
        ];
      } else if (allPokemons.isNotEmpty) {
        _opponentDeck = List.generate(
          3,
          (index) => allPokemons[index % allPokemons.length],
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _initFighters();
        _isLoading = false;
      });
    }
  }

  void _initFighters() {
    if (widget.playerDeck.isEmpty || _opponentDeck.isEmpty) return;

    final pCard = _activePlayer;
    final oCard = _activeOpponent;

    final pHp = int.tryParse(pCard.hp) ?? 100;
    final oHp = int.tryParse(oCard.hp) ?? 100;

    _playerHp = pHp;
    _maxPlayerHp = pHp;
    _opponentHp = oHp;
    _maxOpponentHp = oHp;
    _battleLog = '${pCard.name} contre ${oCard.name}';
  }

  PokemonData get _activePlayer {
    if (widget.playerDeck.isEmpty ||
        _playerActiveIndex >= widget.playerDeck.length) {
      return PokemonData(
        name: 'En attente...',
        hp: '100',
        type: '',
        imageUrl: '',
        attacks: [],
      );
    }
    return widget.playerDeck[_playerActiveIndex];
  }

  PokemonData get _activeOpponent {
    if (_opponentDeck.isEmpty ||
        _opponentActiveIndex >= _opponentDeck.length) {
      return PokemonData(
        name: 'En attente...',
        hp: '100',
        type: '',
        imageUrl: '',
        attacks: [],
      );
    }
    return _opponentDeck[_opponentActiveIndex];
  }

  void _executePlayerAttack(PokemonAttackData attack) async {
    if (_isAttacking || _isFinished) return;

    setState(() {
      _isAttacking = true;
    });

    int dmg = int.tryParse(attack.damage) ?? 20;
    if (dmg <= 0) dmg = 15;

    final newOppHp = (_opponentHp - dmg).clamp(0, _maxOpponentHp);

    setState(() {
      _opponentHp = newOppHp;
      _battleLog = '${_activePlayer.name} lance ${attack.name} ! $dmg dégâts infligés.';
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (_opponentHp <= 0) {
      if (_opponentActiveIndex < _opponentDeck.length - 1) {
        _opponentActiveIndex++;
        final nextOpponent = _activeOpponent;
        final nextHp = int.tryParse(nextOpponent.hp) ?? 100;

        setState(() {
          _opponentHp = nextHp;
          _maxOpponentHp = nextHp;
          _battleLog =
              '${_opponentDeck[_opponentActiveIndex - 1].name} est K.O. ! L\'adversaire envoie ${nextOpponent.name} !';
          _isAttacking = false;
        });
        return;
      } else {
        setState(() {
          _battleLog = 'Les 3 Pokémon adverses sont K.O. ! VICTOIRE FINALE ! 🎉';
          _isFinished = true;
          _isAttacking = false;
        });
        return;
      }
    }

    if (_activeOpponent.attacks.isNotEmpty) {
      final oppAttack = _activeOpponent.attacks.first;
      int oppDmg = int.tryParse(oppAttack.damage) ?? 20;
      if (oppDmg <= 0) oppDmg = 15;

      final newPlHp = (_playerHp - oppDmg).clamp(0, _maxPlayerHp);

      setState(() {
        _playerHp = newPlHp;
        _battleLog +=
            '\n${_activeOpponent.name} riposte avec ${oppAttack.name} ! $oppDmg dégâts subis.';
      });

      if (_playerHp <= 0) {
        await Future.delayed(const Duration(milliseconds: 800));

        if (_playerActiveIndex < widget.playerDeck.length - 1) {
          _playerActiveIndex++;
          final nextPlayer = _activePlayer;
          final nextPlHp = int.tryParse(nextPlayer.hp) ?? 100;

          setState(() {
            _playerHp = nextPlHp;
            _maxPlayerHp = nextPlHp;
            _battleLog =
                '${widget.playerDeck[_playerActiveIndex - 1].name} est K.O. ! Vous envoyez ${nextPlayer.name} !';
          });
        } else {
          setState(() {
            _battleLog = 'Vos 3 Pokémon sont K.O. ! DÉFAITE FINALE... 💀';
            _isFinished = true;
          });
        }
      }
    }

    setState(() {
      _isAttacking = false;
    });
  }

  Color _getHpColor(double ratio) {
    if (ratio > 0.5) return Colors.green.shade600;
    if (ratio > 0.2) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Widget _buildCombatActionBar() {
    if (_isFinished) return const SizedBox.shrink();

    final activePokemon = _activePlayer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Attaques de ${activePokemon.name} :',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/combat'),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                  label: const Text(
                    'Abandonner',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (activePokemon.attacks.isEmpty)
              const Text(
                'Aucune attaque disponible.',
                style: TextStyle(color: Colors.white70),
              )
            else
              Row(
                children: activePokemon.attacks.map((attack) {
                  final dmgStr =
                      attack.damage.isNotEmpty ? ' (${attack.damage})' : '';
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: _isAttacking
                            ? null
                            : () => _executePlayerAttack(attack),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '${attack.name}$dmgStr',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _opponentDeck.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Combat en Duel 3v3'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isFinished) {
      final isVictory =
          _opponentActiveIndex >= _opponentDeck.length - 1 && _opponentHp <= 0;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultat du Combat'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVictory ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 80,
                  color: isVictory ? Colors.amber.shade700 : Colors.red.shade700,
                ),
                const SizedBox(height: 20),
                Text(
                  isVictory ? 'Victoire Éclatante ! 🎉' : 'Défaite... 💀',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color:
                        isVictory ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _battleLog,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/combat'),
                  icon: const Icon(Icons.replay),
                  label: const Text('Retour à l\'arène'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVictory
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final opponentRatio = _maxOpponentHp > 0
        ? (_opponentHp / _maxOpponentHp).clamp(0.0, 1.0)
        : 0.0;
    final playerRatio = _maxPlayerHp > 0
        ? (_playerHp / _maxPlayerHp).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combat en Duel 3v3'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/combat'),
        ),
      ),
      bottomNavigationBar: _buildCombatActionBar(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. CARTE ADVERSAIRE ACTIF
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adversaire (${_opponentActiveIndex + 1}/${_opponentDeck.length}) : ${_activeOpponent.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'PV $_opponentHp / $_maxOpponentHp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getHpColor(opponentRatio),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: opponentRatio,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getHpColor(opponentRatio),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PokemonCard(data: _activeOpponent, width: 105),
                ],
              ),
            ),

            // 2. BADGE VS ET BATTLE LOG
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '⚔️ ARENE DUEL 3v3 ⚔️',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _battleLog,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. CARTE JOUEUR ACTIF
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  PokemonCard(data: _activePlayer, width: 105),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Votre Pokémon (${_playerActiveIndex + 1}/${widget.playerDeck.length}) : ${_activePlayer.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'PV $_playerHp / $_maxPlayerHp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getHpColor(playerRatio),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: playerRatio,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getHpColor(playerRatio),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
