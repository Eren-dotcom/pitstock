/// A line item parsed from a bill OCR or a live camera scan,
/// shown in a review screen before being committed to inventory.
class ScannedItem {
  String name;
  String? partNumber;
  int quantity;
  double price;
  double? gstPercent;
  String? matchedPartId; // if it maps to an existing Part
  double confidence; // 0..1 from AI parsing
  bool selected;

  ScannedItem({
    required this.name,
    this.partNumber,
    this.quantity = 1,
    this.price = 0,
    this.gstPercent,
    this.matchedPartId,
    this.confidence = 1.0,
    this.selected = true,
  });
}
