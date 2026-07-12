import 'package:openfoodfacts/openfoodfacts.dart';

/// A normalised food product from Open Food Facts (or a manual/AI entry),
/// canonicalised to per-100 g nutriments. Maps 1:1 onto the `FoodItems` table.
class OffProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? servingSizeRaw; // free-text, e.g. "30 g"
  final double? servingGrams; // parsed grams, or null
  final double? kcal100;
  final double? carbs100;
  final double? protein100;
  final double? fat100;
  final double? sugar100;
  final double? fiber100;
  final double? salt100;

  const OffProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.servingSizeRaw,
    this.servingGrams,
    this.kcal100,
    this.carbs100,
    this.protein100,
    this.fat100,
    this.sugar100,
    this.fiber100,
    this.salt100,
  });
}

/// Thin wrapper over the `openfoodfacts` package. Configure [init] once at
/// startup (OFF blocks requests without a real User-Agent — that is a hard
/// requirement, not politeness). All data is ODbL-licensed; surface the
/// attribution in the app's About screen.
class OffClient {
  OffClient._();

  static const _fields = [
    ProductField.BARCODE,
    ProductField.NAME,
    ProductField.BRANDS,
    ProductField.IMAGE_FRONT_URL,
    ProductField.QUANTITY,
    ProductField.SERVING_SIZE,
    ProductField.NUTRIMENTS,
  ];

  /// Call once before any lookup. Sets the mandatory User-Agent + locale.
  static void init({String appName = 'NOOP', String? appUrl}) {
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: appName, url: appUrl);
    OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.GERMAN];
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.GERMANY;
  }

  /// Look up a single product by barcode. Returns null if OFF has no match.
  static Future<OffProduct?> fetchByBarcode(String barcode) async {
    final config = ProductQueryConfiguration(
      barcode,
      version: ProductQueryVersion.v3,
      language: OpenFoodFactsLanguage.GERMAN,
      country: OpenFoodFactsCountry.GERMANY,
      fields: _fields,
    );
    final res = await OpenFoodAPIClient.getProductV3(config);
    final p = res.product;
    if (p == null) return null;
    return _map(p, fallbackBarcode: barcode);
  }

  /// Free-text product search (the primary path on desktop, where the camera
  /// scanner is unavailable). Returns up to [pageSize] products.
  static Future<List<OffProduct>> searchByName(String query,
      {int pageSize = 25}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final config = ProductSearchQueryConfiguration(
      parametersList: [
        SearchTerms(terms: [trimmed]),
        const SortBy(option: SortOption.POPULARITY),
        PageSize(size: pageSize),
        const PageNumber(page: 1),
      ],
      language: OpenFoodFactsLanguage.GERMAN,
      country: OpenFoodFactsCountry.GERMANY,
      fields: _fields,
      version: ProductQueryVersion.v3,
    );
    final result = await OpenFoodAPIClient.searchProducts(null, config);
    final products = result.products ?? const <Product>[];
    return [
      for (final p in products)
        if ((p.productName ?? '').trim().isNotEmpty) _map(p),
    ];
  }

  // ── mapping ────────────────────────────────────────────────────────────────

  static OffProduct _map(Product p, {String? fallbackBarcode}) {
    final n = p.nutriments;
    double? per100(Nutrient nutrient) =>
        n?.getValue(nutrient, PerSize.oneHundredGrams);
    return OffProduct(
      barcode: p.barcode ?? fallbackBarcode ?? '',
      name: (p.productName ?? '').trim(),
      brand: (p.brands ?? '').trim().isEmpty ? null : p.brands!.trim(),
      imageUrl: p.imageFrontUrl,
      servingSizeRaw: p.servingSize,
      servingGrams: parseGrams(p.servingSize),
      kcal100: per100(Nutrient.energyKCal),
      carbs100: per100(Nutrient.carbohydrates),
      protein100: per100(Nutrient.proteins),
      fat100: per100(Nutrient.fat),
      sugar100: per100(Nutrient.sugars),
      fiber100: per100(Nutrient.fiber),
      salt100: per100(Nutrient.salt),
    );
  }

  /// Parse the leading gram quantity out of a free-text serving/quantity string
  /// ("30 g", "1 portion (45g)", "330ml" → null for non-gram units). Best-effort.
  static double? parseGrams(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'([\d]+(?:[.,]\d+)?)\s*g\b', caseSensitive: false)
        .firstMatch(raw);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }
}
