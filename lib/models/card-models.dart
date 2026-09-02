class PokemonAttackData {
  final String cost;
  final String name;
  final String damage;
  final String description;

  PokemonAttackData({
    required this.cost,
    required this.name,
    required this.damage,
    required this.description,
  });

  factory PokemonAttackData.fromJson(Map<String, dynamic> json) {
    final costList = json['cost'] as List?;
    return PokemonAttackData(
      cost: costList != null && costList.isNotEmpty
          ? costList.map((e) => e.toString()).join(' ')
          : '',
      name: json['name']?.toString() ?? '',
      damage: json['damage']?.toString() ?? '',
      description: json['effect']?.toString() ?? json['description']?.toString() ?? '',
    );
  }
}

class PokemonStat {
  final String type; // ex: "Water"
  final String value; // ex: "x2" ou "-30"

  PokemonStat({required this.type, required this.value});

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class PokemonData {
  final String name;
  final String hp;
  final String type;
  final String imageUrl;
  final List<PokemonAttackData> attacks;

  // Nouvelles propriétés ajoutées
  final PokemonStat? weakness;
  final PokemonStat? resistance;
  final int retreatCost;

  PokemonData({
    required this.name,
    required this.hp,
    required this.type,
    required this.imageUrl,
    required this.attacks,
    this.weakness,
    this.resistance,
    this.retreatCost = 0,
  });

  factory PokemonData.fromJson(Map<String, dynamic> json) {
    final typesList = json['types'] as List?;
    final weaknessesList = json['weaknesses'] as List?;
    final resistancesList = json['resistances'] as List?;

    String img = json['image']?.toString() ?? '';
    if (img.isNotEmpty && !img.endsWith('.png')) {
      img = '$img/high.png';
    }

    return PokemonData(
      name: json['name']?.toString() ?? '',
      hp: json['hp']?.toString() ?? '0',
      type: (typesList != null && typesList.isNotEmpty) ? typesList.first.toString() : '',
      imageUrl: img,
      attacks: (json['attacks'] as List? ?? [])
          .map((a) => PokemonAttackData.fromJson(a as Map<String, dynamic>))
          .toList(),
      weakness: (weaknessesList != null && weaknessesList.isNotEmpty)
          ? PokemonStat.fromJson(weaknessesList.first as Map<String, dynamic>)
          : null,
      resistance: (resistancesList != null && resistancesList.isNotEmpty)
          ? PokemonStat.fromJson(resistancesList.first as Map<String, dynamic>)
          : null,
      retreatCost: json['retreat'] is int
          ? json['retreat'] as int
          : (int.tryParse(json['retreat']?.toString() ?? '0') ?? 0),
    );
  }
}

