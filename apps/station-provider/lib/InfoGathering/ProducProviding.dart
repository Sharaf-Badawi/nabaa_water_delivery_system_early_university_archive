import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ChoosedProductProvidedController.dart';

class ProductSelectionScreen extends StatefulWidget {
  final int locationIndex;

  ProductSelectionScreen({
    required this.locationIndex,
  });

  @override
  _ProductSelectionScreenState createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final ProductController productController = Get.find<ProductController>();
  final _formKey = GlobalKey<FormState>(); // Form key to validate price fields

  List<DocumentSnapshot> productList = []; // Store fetched product data
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Fetch products when the screen is initialized
  }

  // Method to fetch products from Firestore
  Future<void> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
      setState(() {
        productList = snapshot.docs; // Store fetched product data
        isLoading = false; // Stop loading state
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading in case of error
      });
      print('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text("إختر المنتجات وتسعيرها"),
        backgroundColor: Colors.lightBlue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Save the selected products and navigate back to the previous screen
            if (_formKey.currentState!.validate()) {
              saveSelectedProducts();
            }
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Form(
        key: _formKey, // Wrap the form around the body
        child: ListView.builder(
          itemCount: productList.length,
          itemBuilder: (context, index) {
            var product = productList[index];
            return ProductTile(
              locationIndex: widget.locationIndex,
              productId: product.id,
              productName: product['title'],
              productDescription: product['description'],
              productImageUrl: product['image_url'],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.lightBlueAccent,
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Save the selected products and navigate to the previous screen
            saveSelectedProducts();
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }

  void saveSelectedProducts() async {
    List<Map<String, dynamic>> productsToSave = [];

    // Prepare data for saving
    productController.selectedProducts.forEach((productId, floorPrices) {
      productsToSave.add({
        'product_id': productId,
        'floor_prices': floorPrices,
      });
    });

    // Save selected products under the respective location
    // Navigate back to the previous screen
    Get.back(); // Navigate back to the locations screen
  }
}

class ProductTile extends StatefulWidget {
  final int locationIndex;
  final String productId;
  final String productName;
  final String productDescription;
  final String productImageUrl;

  ProductTile({
    required this.locationIndex,
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productImageUrl,
  });

  @override
  _ProductTileState createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  final ProductController productController = Get.find<ProductController>();
  bool _isSelected = false;
  Map<String, double> _floorPrices = {
    'G': 0.0,
    '1': 0.0,
    '2': 0.0,
    '3': 0.0,
    '4': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Image.network(
              widget.productImageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(widget.productName),
            subtitle: Text(widget.productDescription),
            trailing: Checkbox(
              checkColor: Colors.white,
              activeColor: Colors.lightBlueAccent,
              value: _isSelected,
              onChanged: (newValue) {
                setState(() {
                  _isSelected = newValue!;
                  if (_isSelected) {
                    productController.selectProduct(widget.locationIndex, widget.productId, _floorPrices);
                  } else {
                    productController.selectProduct(widget.locationIndex, widget.productId, {});
                  }
                });
              },
            ),
          ),
          if (_isSelected) ..._buildPriceFields(),
        ],
      ),
    );
  }

  // Build price input fields for each floor
  List<Widget> _buildPriceFields() {
    List<Widget> priceFields = [];

    _floorPrices.forEach((floor, price) {
      priceFields.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              suffixText: 'دينار',
              labelText: 'تسعيرة الطابق:  $floor',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يجب أن تضع تسعيراً';
              }
              if (double.tryParse(value) == null) {
                return 'ضع رقماً صحيحاً';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _floorPrices[floor] = double.tryParse(value) ?? 0.0;
              });
              productController.selectProduct(widget.locationIndex, widget.productId, _floorPrices);
            },
          ),
        ),
      );
    });
    return priceFields;
  }
}
