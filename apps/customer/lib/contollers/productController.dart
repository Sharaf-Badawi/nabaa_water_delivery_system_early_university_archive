import 'package:get/get.dart';

class ProductController extends GetxController {
  // A map to store selected products and their quantities
  var selectedProducts = {}.obs;

  // Function to add or update product quantity
  void addProduct(String productId) {
    if (selectedProducts.containsKey(productId)) {
      if(selectedProducts[productId] < 99 ){
        selectedProducts[productId] +=1;

      }
    } else {
      selectedProducts[productId] = 1;
    }
  }
bool hasselectedproduct(){
if(selectedProducts.isEmpty )
  return false;
else
  return true;

  }
  // Function to reduce product quantity or remove it if zero
  void removeProduct(String productId) {
    if (selectedProducts.containsKey(productId)) {
      if (selectedProducts[productId] > 1) {
        selectedProducts[productId] -= 1;
      } else {
        selectedProducts.remove(productId);
      }
    }
  }

  // Clear all selected products (for use when needed)
  void clearSelectedProducts() {
    selectedProducts.clear();
  }
}
