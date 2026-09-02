import 'package:flutter/material.dart';

import '../models/card-models.dart';

class PokemonCardHeader extends StatelessWidget {
  final String name;
  final String hp;
  final String type;

  const PokemonCardHeader({
    Key? key,
    required this.name,
    required this.hp,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Text(
              'PV ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Text(
              hp,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            // On peut remplacer l'icône par une image du type (ex: icône de flamme)
            CircleAvatar(
              radius: 12,
              backgroundColor: _getTypeColor(type),
              child: Text(
                type[0],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }
}

// --- 2. L'Illustration de la carte ---
class PokemonCardArt extends StatelessWidget {
  final String imageUrl;

  const PokemonCardArt({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      // On utilise un Container coloré si l'image est vide ou en cours de chargement
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

// --- 3. Une Attaque individuelle ---
class PokemonAttackItem extends StatelessWidget {
  final PokemonAttackData attack;

  const PokemonAttackItem({Key? key, required this.attack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                attack.cost,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attack.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                attack.damage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (attack.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              attack.description,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}
