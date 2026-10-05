import 'package:get/get.dart';

class ProductController extends GetxController {
  // Store the selected products and their floor prices in a reactive map
  var selectedProducts = <int, Map<String, Map<String, double>>>{}.obs;

  // Method to select or deselect a product for a given location
  void selectProduct(int locationIndex, String productId, Map<String, double> floorPrices) {
    if (!selectedProducts.containsKey(locationIndex)) {
      selectedProducts[locationIndex] = {};
    }

    if (floorPrices.isEmpty) {
      selectedProducts[locationIndex]?.remove(productId); // Remove product if unselected
    } else {
      selectedProducts[locationIndex]?[productId] = floorPrices; // Add/update product with its prices
    }

    update(); // Notify listeners
  }

  // Get the selected products for a specific location
  Map<String, Map<String, double>> getSelectedProductsForLocation(int locationIndex) {
    return selectedProducts[locationIndex] ?? {};
  }

  // Clear all selected products (optional if needed)
  void clearSelectedProducts() {
    selectedProducts.clear();
  }
}
