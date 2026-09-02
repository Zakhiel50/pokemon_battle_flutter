import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

import '../../models/card-models.dart';
import '../../services/pokemon_api_service.dart';
import '../../services/pokemon_type_effectiveness.dart';
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
  int _playerActiveIndex = 0;

  // Suivi indépendant des PV de chaque carte des decks 3v3
  List<int> _playerHpList = [];
  List<int> _maxPlayerHpList = [];

  List<int> _opponentHpList = [];
  List<int> _maxOpponentHpList = [];

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
    List<PokemonData> apiOpponentCards =
        await PokemonApiService.fetchRandomPokemonCards(3);

    if (apiOpponentCards.length >= 3) {
      _opponentDeck = apiOpponentCards;
    } else {
      try {
        final String jsonString = await rootBundle.loadString(
          'assets/pokemon-data.json',
        );
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final allPokemons = jsonList
            .map((json) => PokemonData.fromJson(json as Map<String, dynamic>))
            .toList();

        if (allPokemons.isNotEmpty) {
          _opponentDeck = List.generate(
            3,
            (index) => allPokemons[index % allPokemons.length],
          );
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _initFighters();
        _isLoading = false;
      });
    }
  }

  void _initFighters() {
    if (widget.playerDeck.isEmpty || _opponentDeck.isEmpty) return;

    _playerHpList = widget.playerDeck.map((c) {
      final hp = int.tryParse(c.hp) ?? 100;
      return hp <= 0 ? 100 : hp;
    }).toList();
    _maxPlayerHpList = List.from(_playerHpList);

    _opponentHpList = _opponentDeck.map((c) {
      final hp = int.tryParse(c.hp) ?? 100;
      return hp <= 0 ? 100 : hp;
    }).toList();
    _maxOpponentHpList = List.from(_opponentHpList);

    final pCard = _activePlayer;
    final oCard = _activeOpponent;

    _battleLog =
        '${pCard.name} (${pCard.type}) contre ${oCard.name} (${oCard.type})';
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

  int get _playerHp =>
      _playerHpList.isNotEmpty && _playerActiveIndex < _playerHpList.length
          ? _playerHpList[_playerActiveIndex]
          : 100;
  set _playerHp(int val) {
    if (_playerHpList.isNotEmpty &&
        _playerActiveIndex < _playerHpList.length) {
      _playerHpList[_playerActiveIndex] = val;
    }
  }

  int get _maxPlayerHp =>
      _maxPlayerHpList.isNotEmpty &&
              _playerActiveIndex < _maxPlayerHpList.length
          ? _maxPlayerHpList[_playerActiveIndex]
          : 100;

  int get _opponentHp =>
      _opponentHpList.isNotEmpty &&
              _opponentActiveIndex < _opponentHpList.length
          ? _opponentHpList[_opponentActiveIndex]
          : 100;
  set _opponentHp(int val) {
    if (_opponentHpList.isNotEmpty &&
        _opponentActiveIndex < _opponentHpList.length) {
      _opponentHpList[_opponentActiveIndex] = val;
    }
  }

  int get _maxOpponentHp =>
      _maxOpponentHpList.isNotEmpty &&
              _opponentActiveIndex < _maxOpponentHpList.length
          ? _maxOpponentHpList[_opponentActiveIndex]
          : 100;

  // L'utilisateur change de Pokémon pendant le combat (compte comme 1 action -> passe le tour)
  void _switchPlayerPokemon(int newIndex) async {
    if (_isAttacking || _isFinished) return;
    if (newIndex == _playerActiveIndex) return;
    if (_playerHpList[newIndex] <= 0) return;

    final previousName = _activePlayer.name;

    setState(() {
      _isAttacking = true;
      _playerActiveIndex = newIndex;
      _battleLog =
          'Vous rappelez $previousName et envoyez ${_activePlayer.name} (${_activePlayer.type}) !';
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    // Le changement de Pokémon consomme le tour -> Riposte immédiate de l'adversaire
    if (_activeOpponent.attacks.isNotEmpty && _opponentHp > 0) {
      final oppAttack = _activeOpponent.attacks.first;
      int oppBaseDmg =
          int.tryParse(oppAttack.damage.replaceAll(RegExp(r'[^0-9]'), '')) ??
              20;
      if (oppBaseDmg <= 0) oppBaseDmg = 15;

      final oppEffectResult = PokemonTypeEffectiveness.getMultiplier(
        _activeOpponent.type,
        _activePlayer.type,
      );

      int finalOppDmg = (oppBaseDmg * oppEffectResult.multiplier).round();
      final newPlHp = (_playerHp - finalOppDmg).clamp(0, _maxPlayerHp);

      String oppLog =
          '\n${_activeOpponent.name} (${_activeOpponent.type}) riposte pendant le changement avec ${oppAttack.name} ! $finalOppDmg dégâts subis.';
      if (oppEffectResult.label.isNotEmpty) {
        oppLog += ' (${oppEffectResult.label})';
      }

      setState(() {
        _playerHp = newPlHp;
        _battleLog += oppLog;
      });

      if (_playerHp <= 0) {
        await Future.delayed(const Duration(milliseconds: 800));

        bool hasLiving = _playerHpList.any((hp) => hp > 0);
        if (hasLiving) {
          final nextLiving = _playerHpList.indexWhere((hp) => hp > 0);
          setState(() {
            _playerActiveIndex = nextLiving;
            _battleLog =
                '${_activePlayer.name} est K.O. ! Vous envoyez ${_activePlayer.name} (${_activePlayer.type}) !';
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

  void _showSwitchPokemonModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Changer de Pokémon (Consomme 1 tour)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.playerDeck.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final pokemon = widget.playerDeck[index];
                    final currentHp = _playerHpList[index];
                    final maxHp = _maxPlayerHpList[index];
                    final isCurrentActive = index == _playerActiveIndex;
                    final isKo = currentHp <= 0;

                    return GestureDetector(
                      onTap: (isCurrentActive || isKo || _isAttacking)
                          ? null
                          : () {
                              Navigator.pop(context);
                              _switchPlayerPokemon(index);
                            },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentActive
                              ? Colors.amber.shade900.withValues(alpha: 0.3)
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentActive
                                ? Colors.amber
                                : (isKo ? Colors.red : Colors.grey.shade600),
                            width: isCurrentActive ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            PokemonCard(data: pokemon, width: 100),
                            const SizedBox(height: 4),
                            Text(
                              pokemon.name,
                              style: TextStyle(
                                color: isKo ? Colors.red : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              isKo ? 'K.O.' : 'PV $currentHp / $maxHp',
                              style: TextStyle(
                                color: isKo
                                    ? Colors.red.shade300
                                    : _getHpColor(
                                        maxHp > 0 ? currentHp / maxHp : 0),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCurrentActive)
                              const Text(
                                '(Actif)',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _executePlayerAttack(PokemonAttackData attack) async {
    if (_isAttacking || _isFinished) return;

    setState(() {
      _isAttacking = true;
    });

    int baseDmg =
        int.tryParse(attack.damage.replaceAll(RegExp(r'[^0-9]'), '')) ?? 20;
    if (baseDmg <= 0) baseDmg = 15;

    final playerType = _activePlayer.type;
    final opponentType = _activeOpponent.type;
    final effectResult =
        PokemonTypeEffectiveness.getMultiplier(playerType, opponentType);

    int finalDmg = (baseDmg * effectResult.multiplier).round();
    final newOppHp = (_opponentHp - finalDmg).clamp(0, _maxOpponentHp);

    String logMsg =
        '${_activePlayer.name} ($playerType) lance ${attack.name} ! $finalDmg dégâts infligés.';
    if (effectResult.label.isNotEmpty) {
      logMsg += '\n${effectResult.label}';
    }

    setState(() {
      _opponentHp = newOppHp;
      _battleLog = logMsg;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (_opponentHp <= 0) {
      if (_opponentActiveIndex < _opponentDeck.length - 1) {
        _opponentActiveIndex++;
        final nextOpponent = _activeOpponent;
        final nextHp = int.tryParse(nextOpponent.hp) ?? 100;

        setState(() {
          _opponentHp = nextHp;
          _battleLog =
              '${_opponentDeck[_opponentActiveIndex - 1].name} est K.O. ! L\'adversaire envoie ${nextOpponent.name} (${nextOpponent.type}) !';
          _isAttacking = false;
        });
        return;
      } else {
        setState(() {
          _battleLog =
              'Les 3 Pokémon adverses sont K.O. ! VICTOIRE FINALE ! 🎉';
          _isFinished = true;
          _isAttacking = false;
        });
        return;
      }
    }

    // Riposte du Pokémon adverse actif
    if (_activeOpponent.attacks.isNotEmpty) {
      final oppAttack = _activeOpponent.attacks.first;
      int oppBaseDmg =
          int.tryParse(oppAttack.damage.replaceAll(RegExp(r'[^0-9]'), '')) ??
              20;
      if (oppBaseDmg <= 0) oppBaseDmg = 15;

      final oppEffectResult = PokemonTypeEffectiveness.getMultiplier(
        _activeOpponent.type,
        _activePlayer.type,
      );

      int finalOppDmg = (oppBaseDmg * oppEffectResult.multiplier).round();
      final newPlHp = (_playerHp - finalOppDmg).clamp(0, _maxPlayerHp);

      String oppLog =
          '\n${_activeOpponent.name} (${_activeOpponent.type}) riposte avec ${oppAttack.name} ! $finalOppDmg dégâts subis.';
      if (oppEffectResult.label.isNotEmpty) {
        oppLog += ' (${oppEffectResult.label})';
      }

      setState(() {
        _playerHp = newPlHp;
        _battleLog += oppLog;
      });

      if (_playerHp <= 0) {
        await Future.delayed(const Duration(milliseconds: 800));

        bool hasLiving = _playerHpList.any((hp) => hp > 0);
        if (hasLiving) {
          final nextLiving = _playerHpList.indexWhere((hp) => hp > 0);
          setState(() {
            _playerActiveIndex = nextLiving;
            _battleLog =
                '${_activePlayer.name} est K.O. ! Vous envoyez ${_activePlayer.name} (${_activePlayer.type}) !';
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
                const SizedBox(width: 4),
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
                  onPressed: _isAttacking ? null : _showSwitchPokemonModal,
                  icon: const Icon(Icons.sync, color: Colors.amber, size: 16),
                  label: const Text(
                    'Changer 🔄',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
                    'Quitter',
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
                if (isVictory) ...[
                  ElevatedButton.icon(
                    onPressed: () => context.push('/combat/booster'),
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Ouvrir mon Booster (2 cartes) 🎁'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: () => context.go('/combat'),
                  icon: const Icon(Icons.replay),
                  label: const Text('Retour à l\'arène'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isVictory ? Colors.grey.shade800 : Colors.red.shade700,
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
