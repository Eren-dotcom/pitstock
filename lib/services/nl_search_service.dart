import '../data/catalogue_data.dart';
import 'search_service.dart';

/// Result of parsing a natural-language query into structured filters.
class NlParseResult {
  final SearchFilters filters;

  /// Human-readable chips describing what was understood, e.g.
  /// ["Brakes", "Maruti Suzuki", "under ₹1000"].
  final List<String> understood;

  /// Leftover free-text terms that became the fuzzy query.
  final String freeText;

  NlParseResult({
    required this.filters,
    required this.understood,
    required this.freeText,
  });

  bool get isEmpty => understood.isEmpty && freeText.trim().isEmpty;
}

/// Offline natural-language search with Indian automotive synonyms & garage vocabulary.
class NlSearchService {
  // ---- synonym dictionaries (lower-cased keys) ----
  static final Map<String, String> _categorySynonyms = {
    // Brakes & Friction
    'brake': 'Brakes',
    'brakes': 'Brakes',
    'brake pad': 'Brakes',
    'brake pads': 'Brakes',
    'disc': 'Brakes',
    'rotor': 'Brakes',
    'pad': 'Brakes',
    'pads': 'Brakes',
    'brake shoe': 'Brakes',
    'brake shoo': 'Brakes',
    'caliper': 'Brakes',

    // Filters
    'filter': 'Filters',
    'filters': 'Filters',
    'air filter': 'Filters',
    'oil filter': 'Filters',
    'ac filter': 'Filters',
    'cabin filter': 'Filters',
    'fuel filter': 'Filters',
    'diesel filter': 'Filters',

    // Battery
    'battery': 'Battery',
    'batteries': 'Battery',
    'battri': 'Battery',
    'accumulator': 'Battery',

    // Tyres
    'tyre': 'Tyres',
    'tyres': 'Tyres',
    'tire': 'Tyres',
    'tires': 'Tyres',
    'tair': 'Tyres',
    'radial': 'Tyres',

    // Engine & Powertrain
    'engine': 'Engine',
    'piston': 'Engine',
    'valve': 'Engine',
    'gasket': 'Engine',
    'timing chain': 'Engine',

    // Electrical
    'electrical': 'Electrical',
    'wiring': 'Electrical',
    'self starter': 'Electrical',
    'starter': 'Electrical',
    'self motor': 'Electrical',
    'alternator': 'Electrical',
    'dynamo': 'Electrical',
    'horn': 'Electrical',
    'relay': 'Electrical',
    'fuse': 'Electrical',

    // Lighting
    'light': 'Lighting',
    'lights': 'Lighting',
    'headlight': 'Lighting',
    'head light': 'Lighting',
    'tail light': 'Lighting',
    'bulb': 'Lighting',
    'bulbs': 'Lighting',
    'led': 'Lighting',
    'batti': 'Lighting',
    'fog light': 'Lighting',

    // Suspension
    'suspension': 'Suspension',
    'shock': 'Suspension',
    'shocker': 'Suspension',
    'shockers': 'Suspension',
    'absorber': 'Suspension',
    'kamani': 'Suspension',
    'chimta': 'Suspension',
    'arm': 'Suspension',
    'control arm': 'Suspension',
    'strut': 'Suspension',
    'ball joint': 'Suspension',

    // Lubricants & Fluids
    'oil': 'Lubricants & Fluids',
    'lubricant': 'Lubricants & Fluids',
    'lubricants': 'Lubricants & Fluids',
    'fluid': 'Lubricants & Fluids',
    'engine oil': 'Lubricants & Fluids',
    'mobil': 'Lubricants & Fluids',
    'mobil oil': 'Lubricants & Fluids',
    '5w30': 'Lubricants & Fluids',
    '5w-30': 'Lubricants & Fluids',
    '10w40': 'Lubricants & Fluids',
    '10w-40': 'Lubricants & Fluids',
    'gear oil': 'Lubricants & Fluids',
    'brake fluid': 'Lubricants & Fluids',

    // Cooling
    'coolant': 'Cooling',
    'coolent': 'Cooling',
    'cooling': 'Cooling',
    'radiator': 'Cooling',
    'water pump': 'Cooling',
    'thermostat': 'Cooling',

    // Ignition
    'spark plug': 'Ignition',
    'spark plugs': 'Ignition',
    'plug': 'Ignition',
    'plugs': 'Ignition',
    'ignition': 'Ignition',
    'ignition coil': 'Ignition',

    // Steering
    'steering': 'Steering',
    'tie rod': 'Steering',
    'rack': 'Steering',
    'jump rod': 'Steering',

    // Wipers
    'wiper': 'Wipers',
    'wipers': 'Wipers',
    'wiper blade': 'Wipers',
    'wiper blades': 'Wipers',

    // Bearings
    'bearing': 'Bearings',
    'bearings': 'Bearings',
    'wheel bearing': 'Bearings',

    // Exhaust
    'exhaust': 'Exhaust',
    'silencer': 'Exhaust',
    'muffler': 'Exhaust',

    // Belts & Hoses
    'belt': 'Belts & Hoses',
    'belts': 'Belts & Hoses',
    'fan belt': 'Belts & Hoses',
    'timing belt': 'Belts & Hoses',
    'hose': 'Belts & Hoses',
    'hose pipe': 'Belts & Hoses',

    // Clutch & Transmission
    'clutch': 'Clutch & Transmission',
    'clutch plate': 'Clutch & Transmission',
    'pressure plate': 'Clutch & Transmission',
    'gearbox': 'Clutch & Transmission',
    'transmission': 'Clutch & Transmission',

    // Body & Exterior
    'body': 'Body & Exterior',
    'bumper': 'Body & Exterior',
    'mirror': 'Body & Exterior',
    'side mirror': 'Body & Exterior',
    'grille': 'Body & Exterior',
    'dicky': 'Body & Exterior',
  };

  static final Map<String, String> _vehicleSynonyms = {
    'maruti': 'Maruti Suzuki',
    'suzuki': 'Maruti Suzuki',
    'maruti suzuki': 'Maruti Suzuki',
    'swift': 'Maruti Suzuki',
    'alto': 'Maruti Suzuki',
    'wagonr': 'Maruti Suzuki',
    'wagon r': 'Maruti Suzuki',
    'dzire': 'Maruti Suzuki',
    'baleno': 'Maruti Suzuki',
    'brezza': 'Maruti Suzuki',
    'ertiga': 'Maruti Suzuki',
    'tata': 'Tata Motors',
    'tata motors': 'Tata Motors',
    'nexon': 'Tata Motors',
    'harrier': 'Tata Motors',
    'safari': 'Tata Motors',
    'punch': 'Tata Motors',
    'tiago': 'Tata Motors',
    'mahindra': 'Mahindra',
    'scorpio': 'Mahindra',
    'bolero': 'Mahindra',
    'xuv': 'Mahindra',
    'xuv500': 'Mahindra',
    'xuv700': 'Mahindra',
    'thar': 'Mahindra',
    'hyundai': 'Hyundai',
    'i10': 'Hyundai',
    'i20': 'Hyundai',
    'creta': 'Hyundai',
    'venue': 'Hyundai',
    'verna': 'Hyundai',
    'toyota': 'Toyota',
    'innova': 'Toyota',
    'fortuner': 'Toyota',
    'glanza': 'Toyota',
    'honda': 'Honda',
    'city': 'Honda',
    'amaze': 'Honda',
    'kia': 'Kia',
    'seltos': 'Kia',
    'sonet': 'Kia',
    'renault': 'Renault',
    'kwid': 'Renault',
    'triber': 'Renault',
    'nissan': 'Nissan',
    'magnite': 'Nissan',
    'volkswagen': 'Volkswagen',
    'vw': 'Volkswagen',
    'polo': 'Volkswagen',
    'skoda': 'Skoda',
    'slavia': 'Skoda',
    'kushaq': 'Skoda',
    'universal': 'Universal',
  };

  // Stop words to strip from the leftover free-text query.
  static const _stopWords = {
    'for', 'the', 'a', 'an', 'of', 'in', 'with', 'and', 'to', 'me', 'show',
    'find', 'search', 'get', 'need', 'want', 'please', 'any', 'all', 'some',
    'parts', 'part', 'spare', 'spares', 'price', 'priced', 'cost', 'rs',
    'rupees', 'inr', 'stock', 'ka', 'ki', 'ke', 'bhai', 'wali', 'wala',
  };

  static NlParseResult parse(String input) {
    final filters = SearchFilters();
    final understood = <String>[];
    var text = ' ${input.toLowerCase().trim()} ';

    // ---- 1. Price range ----
    final under = RegExp(r'(under|below|less than|upto|up to|max|cheaper than|ke niche|kam)\s*[₹rs\.]*\s*(\d[\d,]*)')
        .firstMatch(text);
    if (under != null) {
      final v = _toNum(under.group(2)!);
      filters.maxPrice = v;
      understood.add('under ₹${_fmt(v)}');
      text = text.replaceRange(under.start, under.end, ' ');
    }
    final over = RegExp(r'(above|over|more than|greater than|min|starting|se zyada)\s*[₹rs\.]*\s*(\d[\d,]*)')
        .firstMatch(text);
    if (over != null) {
      final v = _toNum(over.group(2)!);
      filters.minPrice = v;
      understood.add('above ₹${_fmt(v)}');
      text = text.replaceRange(over.start, over.end, ' ');
    }
    final between = RegExp(r'(?:between\s*)?[₹rs\.]*\s*(\d[\d,]*)\s*(?:-|to|and|se)\s*[₹rs\.]*\s*(\d[\d,]*)')
        .firstMatch(text);
    if (between != null && filters.minPrice == null && filters.maxPrice == null) {
      final a = _toNum(between.group(1)!);
      final b = _toNum(between.group(2)!);
      filters.minPrice = a < b ? a : b;
      filters.maxPrice = a < b ? b : a;
      understood.add('₹${_fmt(filters.minPrice!)}–₹${_fmt(filters.maxPrice!)}');
      text = text.replaceRange(between.start, between.end, ' ');
    }

    // ---- 2. Stock state ----
    if (RegExp(r'\b(out of stock|out-of-stock|finished|empty|khatam)\b').hasMatch(text)) {
      filters.onlyOutOfStock = true;
      understood.add('out of stock');
      text = text.replaceAll(RegExp(r'\b(out of stock|out-of-stock|finished|empty|khatam)\b'), ' ');
    } else if (RegExp(r'\b(low stock|low-stock|running low|reorder|kam stock)\b').hasMatch(text)) {
      filters.onlyLowStock = true;
      understood.add('low stock');
      text = text.replaceAll(RegExp(r'\b(low stock|low-stock|running low|reorder|kam stock)\b'), ' ');
    } else if (RegExp(r'\b(in stock|in-stock|available|hai)\b').hasMatch(text)) {
      understood.add('in stock');
      text = text.replaceAll(RegExp(r'\b(in stock|in-stock|available|hai)\b'), ' ');
      filters.inStockOnly = true;
    }

    // ---- 3. Sort hints ----
    if (RegExp(r'\b(cheap|cheapest|lowest price|low price|budget|sasta)\b').hasMatch(text)) {
      filters.sort = SearchSort.priceAsc;
      understood.add('cheapest first');
      text = text.replaceAll(RegExp(r'\b(cheap|cheapest|lowest price|low price|budget|sasta)\b'), ' ');
    } else if (RegExp(r'\b(expensive|costliest|highest price|premium|mehnga)\b').hasMatch(text)) {
      filters.sort = SearchSort.priceDesc;
      understood.add('most expensive first');
      text = text.replaceAll(RegExp(r'\b(expensive|costliest|highest price|premium|mehnga)\b'), ' ');
    } else if (RegExp(r'\b(newest|latest|recent|recently added|naya)\b').hasMatch(text)) {
      filters.sort = SearchSort.recent;
      understood.add('recently updated');
      text = text.replaceAll(RegExp(r'\b(newest|latest|recent|recently added|naya)\b'), ' ');
    }

    // ---- 4. OEM / aftermarket ----
    if (RegExp(r'\b(oem|genuine|original|asli)\b').hasMatch(text)) {
      filters.oemOnly = true;
      understood.add('OEM / genuine');
      text = text.replaceAll(RegExp(r'\b(oem|genuine|original|asli)\b'), ' ');
    } else if (RegExp(r'\b(aftermarket|local|duplicate)\b').hasMatch(text)) {
      filters.aftermarketOnly = true;
      understood.add('aftermarket');
      text = text.replaceAll(RegExp(r'\b(aftermarket|local|duplicate)\b'), ' ');
    }

    // ---- 5. Vehicle make / model ----
    for (final entry in _sortByKeyLengthDesc(_vehicleSynonyms)) {
      final pat = RegExp('\\b${RegExp.escape(entry.key)}\\b');
      if (pat.hasMatch(text)) {
        filters.vehicleMakes.add(entry.value);
        if (!understood.contains(entry.value)) understood.add(entry.value);
        text = text.replaceAll(pat, ' ');
      }
    }

    // ---- 6. Brand / maker ----
    for (final brand in CatalogueData.brands) {
      final core = brand.toLowerCase().split(' (').first;
      final pat = RegExp('\\b${RegExp.escape(core)}\\b');
      if (core.length >= 3 && pat.hasMatch(text)) {
        filters.brands.add(brand);
        if (!understood.contains(brand)) understood.add(brand);
        text = text.replaceAll(pat, ' ');
      }
    }

    // ---- 7. Category ----
    for (final entry in _sortByKeyLengthDesc(_categorySynonyms)) {
      final pat = RegExp('\\b${RegExp.escape(entry.key)}\\b');
      if (pat.hasMatch(text)) {
        filters.categories.add(entry.value);
        if (!understood.contains(entry.value)) understood.add(entry.value);
        text = text.replaceAll(pat, ' ');
      }
    }

    // ---- 8. Clean leftover free text ----
    final tokens = text
        .replaceAll(RegExp(r'[₹,]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t) && t.length > 1)
        .toList();
    final freeText = tokens.join(' ').trim();
    filters.query = freeText;

    return NlParseResult(
      filters: filters,
      understood: understood,
      freeText: freeText,
    );
  }

  static List<MapEntry<String, String>> _sortByKeyLengthDesc(
      Map<String, String> m) {
    final list = m.entries.toList();
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }

  static double _toNum(String s) => double.parse(s.replaceAll(',', ''));

  static String _fmt(double v) {
    if (v >= 1000 && v % 1000 == 0) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  static const examples = [
    'brake pads for swift under 1000',
    'bosch filters above 200',
    'shocker for nexon',
    'engine oil 5w-30',
    'cheap tyres for maruti',
    'exide battery 35ah',
    'genuine spark plugs',
  ];
}
