class TypeMultiplierResult {
  final double multiplier;
  final String label;

  TypeMultiplierResult(this.multiplier, this.label);
}

class TypeRules {
  final Set<String> weaknesses;
  final Set<String> resistances;
  final Set<String> immunities;

  TypeRules({
    this.weaknesses = const {},
    this.resistances = const {},
    this.immunities = const {},
  });
}

class PokemonTypeEffectiveness {
  static String normalizeType(String type) {
    final t = type.trim().toLowerCase();
    if (t.contains('electr') || t.contains('électr')) return 'Électrik';
    if (t.contains('tenebr') || t.contains('ténèbr')) return 'Ténèbres';
    if (t.contains('fee') || t.contains('fée')) return 'Fée';
    if (t.contains('plante')) return 'Plante';
    if (t.contains('eau')) return 'Eau';
    if (t.contains('feu')) return 'Feu';
    if (t.contains('combat')) return 'Combat';
    if (t.contains('vol')) return 'Vol';
    if (t.contains('poison')) return 'Poison';
    if (t.contains('sol')) return 'Sol';
    if (t.contains('roche')) return 'Roche';
    if (t.contains('glace')) return 'Glace';
    if (t.contains('psy')) return 'Psy';
    if (t.contains('insecte')) return 'Insecte';
    if (t.contains('spectre')) return 'Spectre';
    if (t.contains('dragon')) return 'Dragon';
    if (t.contains('acier')) return 'Acier';
    if (t.contains('normal')) return 'Normal';
    return type;
  }

  static final Map<String, TypeRules> _typeTable = {
    'Normal': TypeRules(
      weaknesses: {'Combat'},
      immunities: {'Spectre'},
    ),
    'Feu': TypeRules(
      weaknesses: {'Eau', 'Sol', 'Roche'},
      resistances: {'Feu', 'Plante', 'Glace', 'Insecte', 'Acier', 'Fée'},
    ),
    'Eau': TypeRules(
      weaknesses: {'Électrik', 'Plante'},
      resistances: {'Feu', 'Eau', 'Glace', 'Acier'},
    ),
    'Électrik': TypeRules(
      weaknesses: {'Sol'},
      resistances: {'Électrik', 'Vol', 'Acier'},
    ),
    'Plante': TypeRules(
      weaknesses: {'Feu', 'Glace', 'Poison', 'Vol', 'Insecte'},
      resistances: {'Eau', 'Électrik', 'Plante', 'Sol'},
    ),
    'Glace': TypeRules(
      weaknesses: {'Feu', 'Combat', 'Roche', 'Acier'},
      resistances: {'Glace'},
    ),
    'Combat': TypeRules(
      weaknesses: {'Vol', 'Psy', 'Fée'},
      resistances: {'Insecte', 'Roche', 'Ténèbres'},
    ),
    'Poison': TypeRules(
      weaknesses: {'Sol', 'Psy'},
      resistances: {'Plante', 'Combat', 'Poison', 'Insecte', 'Fée'},
    ),
    'Sol': TypeRules(
      weaknesses: {'Eau', 'Plante', 'Glace'},
      resistances: {'Poison', 'Roche'},
      immunities: {'Électrik'},
    ),
    'Vol': TypeRules(
      weaknesses: {'Électrik', 'Glace', 'Roche'},
      resistances: {'Plante', 'Combat', 'Insecte'},
      immunities: {'Sol'},
    ),
    'Psy': TypeRules(
      weaknesses: {'Insecte', 'Spectre', 'Ténèbres'},
      resistances: {'Combat', 'Psy'},
    ),
    'Insecte': TypeRules(
      weaknesses: {'Feu', 'Vol', 'Roche'},
      resistances: {'Plante', 'Combat', 'Sol'},
    ),
    'Roche': TypeRules(
      weaknesses: {'Eau', 'Plante', 'Combat', 'Sol', 'Acier'},
      resistances: {'Normal', 'Feu', 'Poison', 'Vol'},
    ),
    'Spectre': TypeRules(
      weaknesses: {'Spectre', 'Ténèbres'},
      resistances: {'Poison', 'Insecte'},
      immunities: {'Normal', 'Combat'},
    ),
    'Dragon': TypeRules(
      weaknesses: {'Glace', 'Dragon', 'Fée'},
      resistances: {'Feu', 'Eau', 'Électrik', 'Plante'},
    ),
    'Ténèbres': TypeRules(
      weaknesses: {'Combat', 'Insecte', 'Fée'},
      resistances: {'Spectre', 'Ténèbres'},
      immunities: {'Psy'},
    ),
    'Acier': TypeRules(
      weaknesses: {'Feu', 'Combat', 'Sol'},
      resistances: {
        'Normal',
        'Plante',
        'Glace',
        'Vol',
        'Psy',
        'Insecte',
        'Roche',
        'Dragon',
        'Acier',
        'Fée'
      },
      immunities: {'Poison'},
    ),
    'Fée': TypeRules(
      weaknesses: {'Poison', 'Acier'},
      resistances: {'Combat', 'Insecte', 'Ténèbres'},
      immunities: {'Dragon'},
    ),
  };

  /// Calcule le multiplicateur de dégâts en fonction du type de l'attaquant et du type du défenseur
  static TypeMultiplierResult getMultiplier(String attackerType, String defenderType) {
    final normAttacker = normalizeType(attackerType);
    final normDefender = normalizeType(defenderType);

    final rules = _typeTable[normDefender];
    if (rules == null) return TypeMultiplierResult(1.0, '');

    if (rules.immunities.contains(normAttacker)) {
      return TypeMultiplierResult(0.0, 'Immunisé (x0) ! 🛑');
    }
    if (rules.weaknesses.contains(normAttacker)) {
      return TypeMultiplierResult(2.0, 'Super efficace (x2) ! 💥');
    }
    if (rules.resistances.contains(normAttacker)) {
      return TypeMultiplierResult(0.5, 'Pas très efficace (x0.5)... 🛡️');
    }

    return TypeMultiplierResult(1.0, '');
  }
}
