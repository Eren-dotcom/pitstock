import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../models/part.dart';

class SearchFilters {
  String query;
  Set<String> categories;
  Set<String> brands;
  Set<String> vehicleMakes;
  bool onlyLowStock;
  bool onlyOutOfStock;
  bool inStockOnly;
  bool oemOnly;
  bool aftermarketOnly;
  double? minPrice;
  double? maxPrice;
  SearchSort sort;

  SearchFilters({
    this.query = '',
    Set<String>? categories,
    Set<String>? brands,
    Set<String>? vehicleMakes,
    this.onlyLowStock = false,
    this.onlyOutOfStock = false,
    this.inStockOnly = false,
    this.oemOnly = false,
    this.aftermarketOnly = false,
    this.minPrice,
    this.maxPrice,
    this.sort = SearchSort.relevance,
  })  : categories = categories ?? {},
        brands = brands ?? {},
        vehicleMakes = vehicleMakes ?? {};

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      brands.isNotEmpty ||
      vehicleMakes.isNotEmpty ||
      onlyLowStock ||
      onlyOutOfStock ||
      inStockOnly ||
      oemOnly ||
      aftermarketOnly ||
      minPrice != null ||
      maxPrice != null;

  SearchFilters copy() => SearchFilters(
        query: query,
        categories: {...categories},
        brands: {...brands},
        vehicleMakes: {...vehicleMakes},
        onlyLowStock: onlyLowStock,
        onlyOutOfStock: onlyOutOfStock,
        inStockOnly: inStockOnly,
        oemOnly: oemOnly,
        aftermarketOnly: aftermarketOnly,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort,
      );
}

enum SearchSort { relevance, nameAsc, qtyAsc, qtyDesc, priceAsc, priceDesc, recent }

extension SearchSortX on SearchSort {
  String get label => switch (this) {
        SearchSort.relevance => 'Relevance',
        SearchSort.nameAsc => 'Name (A–Z)',
        SearchSort.qtyAsc => 'Qty (low→high)',
        SearchSort.qtyDesc => 'Qty (high→low)',
        SearchSort.priceAsc => 'Price (low→high)',
        SearchSort.priceDesc => 'Price (high→low)',
        SearchSort.recent => 'Recently updated',
      };
}

/// Advanced search: fuzzy matching across name/part-no/brand/vehicle,
/// multi-facet filtering, price range, stock state and sorting.
class SearchService {
  static List<Part> search(List<Part> all, SearchFilters f) {
    final q = f.query.trim().toLowerCase();
    final scored = <(Part, int)>[];

    for (final p in all) {
      // ---- facet filters ----
      if (f.categories.isNotEmpty && !f.categories.contains(p.category)) continue;
      if (f.brands.isNotEmpty && !f.brands.contains(p.brand)) continue;
      if (f.vehicleMakes.isNotEmpty &&
          !(p.vehicleMake != null && f.vehicleMakes.contains(p.vehicleMake))) {
        continue;
      }
      if (f.onlyLowStock && !p.isLowStock) continue;
      if (f.onlyOutOfStock && !p.isOutOfStock) continue;
      if (f.inStockOnly && p.quantity <= 0) continue;
      if (f.oemOnly && p.partType != PartType.oem) continue;
      if (f.aftermarketOnly && p.partType != PartType.aftermarket) continue;
      if (f.minPrice != null && p.sellingPrice < f.minPrice!) continue;
      if (f.maxPrice != null && p.sellingPrice > f.maxPrice!) continue;

      // ---- fuzzy relevance score ----
      int score = 100;
      if (q.isNotEmpty) {
        final haystack =
            '${p.name} ${p.partNumber} ${p.brand} ${p.category} ${p.vehicleMake ?? ''} ${p.vehicleModel ?? ''} ${p.barcode ?? ''}'
                .toLowerCase();
        if (haystack.contains(q)) {
          score = 100 + (p.name.toLowerCase().startsWith(q) ? 50 : 0);
        } else {
          // token set ratio handles typos & word order
          final r = tokenSetRatio(q, haystack);
          if (r < 55) continue; // not relevant enough
          score = r;
        }
      }
      scored.add((p, score));
    }

    // ---- sorting ----
    switch (f.sort) {
      case SearchSort.relevance:
        scored.sort((a, b) => b.$2.compareTo(a.$2));
      case SearchSort.nameAsc:
        scored.sort((a, b) =>
            a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase()));
      case SearchSort.qtyAsc:
        scored.sort((a, b) => a.$1.quantity.compareTo(b.$1.quantity));
      case SearchSort.qtyDesc:
        scored.sort((a, b) => b.$1.quantity.compareTo(a.$1.quantity));
      case SearchSort.priceAsc:
        scored.sort((a, b) => a.$1.sellingPrice.compareTo(b.$1.sellingPrice));
      case SearchSort.priceDesc:
        scored.sort((a, b) => b.$1.sellingPrice.compareTo(a.$1.sellingPrice));
      case SearchSort.recent:
        scored.sort((a, b) => b.$1.updatedAt.compareTo(a.$1.updatedAt));
    }
    return scored.map((e) => e.$1).toList();
  }

  /// Smart suggestions for the search bar (autocomplete).
  static List<String> suggestions(List<Part> all, String q, {int limit = 8}) {
    if (q.trim().isEmpty) return [];
    final ql = q.toLowerCase();
    final pool = <String>{};
    for (final p in all) {
      pool.add(p.name);
      pool.add(p.brand);
      if (p.vehicleModel != null) pool.add('${p.vehicleMake} ${p.vehicleModel}');
      pool.add(p.category);
    }
    final list = pool.where((s) => s.isNotEmpty).toList();
    list.sort((a, b) => ratio(ql, b.toLowerCase()).compareTo(ratio(ql, a.toLowerCase())));
    return list
        .where((s) => s.toLowerCase().contains(ql) || ratio(ql, s.toLowerCase()) > 60)
        .take(limit)
        .toList();
  }
}
