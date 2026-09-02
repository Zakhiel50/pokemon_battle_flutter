import 'package:flutter/material.dart';

import '../models/card-models.dart';

class StatsCard extends StatelessWidget {
  final PokemonStat? weakness;
  final PokemonStat? resistance;
  final int retreatCost;

  const StatsCard({
    Key? key,
    this.weakness,
    this.resistance,
    this.retreatCost = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top double border line
        Container(height: 1, color: const Color(0xFF666666)),
        const SizedBox(height: 2),
        Container(height: 0.5, color: const Color(0xFF999999)),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'weakness',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (weakness != null) ...[
                      const SizedBox(width: 4),
                      _buildEnergyBadge(weakness!.type),
                      const SizedBox(width: 3),
                      Text(
                        weakness!.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Resistance Section
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'resistance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (resistance != null) ...[
                      const SizedBox(width: 4),
                      _buildEnergyBadge(resistance!.type),
                      const SizedBox(width: 3),
                      Text(
                        resistance!.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Vertical divider
              Container(height: 14, width: 1, color: const Color(0xFFAAAAAA)),

              // 3. Retreat Section
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'retreat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (retreatCost > 0) ...[
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          retreatCost,
                          (_) => Padding(
                            padding: const EdgeInsets.only(left: 2.0),
                            child: _buildEnergyBadge('colorless'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom double border line
        Container(height: 0.5, color: const Color(0xFF999999)),
        const SizedBox(height: 2),
        Container(height: 1, color: const Color(0xFF666666)),
      ],
    );
  }

  Widget _buildEnergyBadge(String type) {
    final lowerType = type.toLowerCase().trim();
    Color bgColor;
    Widget iconWidget;

    switch (lowerType) {
      case 'fighting':
      case 'combat':
        bgColor = const Color(0xFFC03028);
        iconWidget = const Icon(
          Icons.fitness_center,
          size: 9,
          color: Colors.white,
        );
        break;
      case 'fire':
      case 'feu':
        bgColor = const Color(0xFFF08030);
        iconWidget = const Icon(
          Icons.local_fire_department,
          size: 10,
          color: Colors.white,
        );
        break;
      case 'water':
      case 'eau':
        bgColor = const Color(0xFF6890F0);
        iconWidget = const Icon(Icons.water_drop, size: 9, color: Colors.white);
        break;
      case 'grass':
      case 'plante':
        bgColor = const Color(0xFF78C850);
        iconWidget = const Icon(Icons.eco, size: 9, color: Colors.white);
        break;
      case 'electric':
      case 'électrik':
      case 'electrik':
        bgColor = const Color(0xFFF8D030);
        iconWidget = const Icon(Icons.bolt, size: 10, color: Colors.black);
        break;
      case 'psychic':
      case 'psy':
        bgColor = const Color(0xFFF85888);
        iconWidget = const Icon(
          Icons.auto_awesome,
          size: 9,
          color: Colors.white,
        );
        break;
      case 'colorless':
      case 'v':
      default:
        bgColor = const Color(0xFFD0D0C8);
        iconWidget = const Icon(Icons.star, size: 9, color: Colors.black87);
        break;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: Colors.black45, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      child: Center(child: iconWidget),
    );
  }
}
