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

/// Offline natural-language search.
///
/// Turns phrases like:
///   "brake pads for swift under 1000"
///   "bosch filters above 200 in stock"
///   "cheap tyres for maruti below ₹5000"
/// into structured [SearchFilters] (category, brand, vehicle make, price range,
/// stock state, sort) PLUS a cleaned free-text query for fuzzy matching.
///
/// 100% on-device, rule + synonym based — no API, no cost, works offline.
class NlSearchService {
  // ---- synonym dictionaries (lower-cased keys) ----
  static final Map<String, String> _categorySynonyms = {
    'brake': 'Brakes',
    'brakes': 'Brakes',
    'brake pad': 'Brakes',
    'brake pads': 'Brakes',
    'disc': 'Brakes',
    'pad': 'Brakes',
    'pads': 'Brakes',
    'filter': 'Filters',
    'filters': 'Filters',
    'air filter': 'Filters',
    'oil filter': 'Filters',
    'battery': 'Battery',
    'batteries': 'Battery',
    'tyre': 'Tyres',
    'tyres': 'Tyres',
    'tire': 'Tyres',
    'tires': 'Tyres',
    'engine': 'Engine',
    'electrical': 'Electrical',
    'wiring': 'Electrical',
    'light': 'Lighting',
    'lights': 'Lighting',
    'headlight': 'Lighting',
    'bulb': 'Lighting',
    'bulbs': 'Lighting',
    'suspension': 'Suspension',
    'shock': 'Suspension',
    'shocker': 'Suspension',
    'shockers': 'Suspension',
    'oil': 'Lubricants & Fluids',
    'lubricant': 'Lubricants & Fluids',
    'lubricants': 'Lubricants & Fluids',
    'fluid': 'Lubricants & Fluids',
    'coolant': 'Cooling',
    'cooling': 'Cooling',
    'radiator': 'Cooling',
    'spark plug': 'Ignition',
    'spark plugs': 'Ignition',
    'plug': 'Ignition',
    'ignition': 'Ignition',
    'steering': 'Steering',
    'wiper': 'Wipers',
    'wipers': 'Wipers',
    'bearing': 'Bearings',
    'bearings': 'Bearings',
    'exhaust': 'Exhaust',
    'silencer': 'Exhaust',
    'belt': 'Belts & Hoses',
    'belts': 'Belts & Hoses',
    'hose': 'Belts & Hoses',
    'clutch': 'Clutch & Transmission',
    'gearbox': 'Clutch & Transmission',
    'transmission': 'Clutch & Transmission',
    'body': 'Body & Exterior',
    'bumper': 'Body & Exterior',
    'mirror': 'Body & Exterior',
  };

  static final Map<String, String> _vehicleSynonyms = {
    'maruti': 'Maruti Suzuki',
    'suzuki': 'Maruti Suzuki',
    'maruti suzuki': 'Maruti Suzuki',
    'tata': 'Tata Motors',
    'mahindra': 'Mahindra',
    'hyundai': 'Hyundai',
    'toyota': 'Toyota',
    'honda': 'Honda',
    'kia': 'Kia',
    'renault': 'Renault',
    'nissan': 'Nissan',
    'volkswagen': 'Volkswagen',
    'vw': 'Volkswagen',
    'skoda': 'Skoda',
    'universal': 'Universal',
  };

  // Stop words to strip from the leftover free-text query.
  static const _stopWords = {
    'for', 'the', 'a', 'an', 'of', 'in', 'with', 'and', 'to', 'me', 'show',
    'find', 'search', 'get', 'need', 'want', 'please', 'any', 'all', 'some',
    'parts', 'part', 'spare', 'spares', 'price', 'priced', 'cost', 'rs',
    'rupees', 'inr', 'stock',
  };

  static NlParseResult parse(String input) {
    final filters = SearchFilters();
    final understood = <String>[];
    var text = ' ${input.toLowerCase().trim()} ';

    // ---- 1. Price range ----
    // "under 1000", "below ₹1000", "less than 1000"
    final under = RegExp(r'(under|below|less than|upto|up to|max|cheaper than)\s*[₹rs\.]*\s*(\d[\d,]*)')
        .firstMatch(text);
    if (under != null) {
      final v = _toNum(under.group(2)!);
      filters.maxPrice = v;
      understood.add('under ₹${_fmt(v)}');
      text = text.replaceRange(under.start, under.end, ' ');
    }
    // "above 200", "over ₹200", "more than 200"
    final over = RegExp(r'(above|over|more than|greater than|min|starting)\s*[₹rs\.]*\s*(\d[\d,]*)')
        .firstMatch(text);
    if (over != null) {
      final v = _toNum(over.group(2)!);
      filters.minPrice = v;
      understood.add('above ₹${_fmt(v)}');
      text = text.replaceRange(over.start, over.end, ' ');
    }
    // "between 200 and 1000" / "200 to 1000"
    final between = RegExp(r'(?:between\s*)?[₹rs\.]*\s*(\d[\d,]*)\s*(?:-|to|and)\s*[₹rs\.]*\s*(\d[\d,]*)')
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
    if (RegExp(r'\b(out of stock|out-of-stock|finished|empty)\b').hasMatch(text)) {
      filters.onlyOutOfStock = true;
      understood.add('out of stock');
      text = text.replaceAll(RegExp(r'\b(out of stock|out-of-stock|finished|empty)\b'), ' ');
    } else if (RegExp(r'\b(low stock|low-stock|running low|reorder)\b').hasMatch(text)) {
      filters.onlyLowStock = true;
      understood.add('low stock');
      text = text.replaceAll(RegExp(r'\b(low stock|low-stock|running low|reorder)\b'), ' ');
    } else if (RegExp(r'\b(in stock|in-stock|available)\b').hasMatch(text)) {
      // handled via post-filter flag using a synthetic min qty: we just note it.
      understood.add('in stock');
      text = text.replaceAll(RegExp(r'\b(in stock|in-stock|available)\b'), ' ');
      filters.inStockOnly = true;
    }

    // ---- 3. Sort hints ----
    if (RegExp(r'\b(cheap|cheapest|lowest price|low price|budget)\b').hasMatch(text)) {
      filters.sort = SearchSort.priceAsc;
      understood.add('cheapest first');
      text = text.replaceAll(RegExp(r'\b(cheap|cheapest|lowest price|low price|budget)\b'), ' ');
    } else if (RegExp(r'\b(expensive|costliest|highest price|premium)\b').hasMatch(text)) {
      filters.sort = SearchSort.priceDesc;
      understood.add('most expensive first');
      text = text.replaceAll(RegExp(r'\b(expensive|costliest|highest price|premium)\b'), ' ');
    } else if (RegExp(r'\b(newest|latest|recent|recently added)\b').hasMatch(text)) {
      filters.sort = SearchSort.recent;
      understood.add('recently updated');
      text = text.replaceAll(RegExp(r'\b(newest|latest|recent|recently added)\b'), ' ');
    }

    // ---- 4. OEM / aftermarket ----
    if (RegExp(r'\b(oem|genuine|original)\b').hasMatch(text)) {
      filters.oemOnly = true;
      understood.add('OEM / genuine');
      text = text.replaceAll(RegExp(r'\b(oem|genuine|original)\b'), ' ');
    } else if (RegExp(r'\b(aftermarket|local|duplicate)\b').hasMatch(text)) {
      filters.aftermarketOnly = true;
      understood.add('aftermarket');
      text = text.replaceAll(RegExp(r'\b(aftermarket|local|duplicate)\b'), ' ');
    }

    // ---- 5. Vehicle make (multi-word first) ----
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
      final core = brand.toLowerCase().split(' (').first; // "Sundaram (TVS)" -> "sundaram"
      final pat = RegExp('\\b${RegExp.escape(core)}\\b');
      if (core.length >= 3 && pat.hasMatch(text)) {
        filters.brands.add(brand);
        if (!understood.contains(brand)) understood.add(brand);
        text = text.replaceAll(pat, ' ');
      }
    }

    // ---- 7. Category (multi-word first) ----
    for (final entry in _sortByKeyLengthDesc(_categorySynonyms)) {
      final pat = RegExp('\\b${RegExp.escape(entry.key)}\\b');
      if (pat.hasMatch(text)) {
        filters.categories.add(entry.value);
        if (!understood.contains(entry.value)) understood.add(entry.value);
        text = text.replaceAll(pat, ' ');
      }
    }

    // ---- 8. Clean leftover free text (becomes model name / fuzzy query) ----
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

  /// Example prompts shown to the user as starter chips.
  static const examples = [
    'brake pads for swift under 1000',
    'bosch filters above 200',
    'cheap tyres for maruti',
    'low stock batteries',
    'genuine spark plugs',
    'oil 5w-30 below ₹2000',
  ];
}
