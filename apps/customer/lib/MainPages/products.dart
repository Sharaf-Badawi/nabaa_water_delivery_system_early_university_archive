import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/MainPages/SelectingOrderType.dart';
import 'package:water_delivery_app/contollers/productController.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductGridScreen extends StatefulWidget {
  final String userId;
  const ProductGridScreen({required this.userId});

  @override
  _ProductGridScreenState createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  String lang = 'ar';
  final ProductController productController = Get.put(ProductController());

  @override
  void initState() {
    super.initState();
    _fetchLanguagePreference();
  }

  Future<void> _fetchLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lang = prefs.getString('language_code') ?? Get.locale!.languageCode;
    });
  }

  Future<bool> _isOffline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text("${AppLocalizations.of(context)!.select_products}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<bool>(
              future: _isOffline(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == true) {
                  return Center(
                    child: Text(
                      'No internet connection. Please try again later.',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(
                        child: Text(
                          'Failed to load products. Please try again later.',
                          style: TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No products available.'));
                    }

                    final products = snapshot.data!.docs;

                    return GridView.builder(
                      padding: EdgeInsets.only(
                        left: 10.0,
                        right: 10.0,
                        top: 10.0,
                        bottom: 70.0, // Add padding at the bottom for the button
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                        MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 4,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final productId = product.id;
                        final productImageUrl = product['image_url'] ?? '';
                        final title = lang == 'ar'
                            ? product['title'] ?? 'No Title'
                            : product['title_en'] ?? 'No Title';
                        final desc = lang == 'ar'
                            ? product['description'] ?? 'No Description'
                            : product['description_en'] ?? 'No Description';

                        return InkWell(
                          onTap: () {
                            productController.addProduct(productId);
                          },
                          child: Card(
                            color: Colors.white,
                            elevation: 5,
                            child: Column(
                              children: [
                                Expanded(
                                  child: productImageUrl.isNotEmpty
                                      ? Image.network(
                                    productImageUrl,
                                    height: 89,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.error), // Error fallback
                                  )
                                      : Icon(Icons.image_not_supported), // Placeholder
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        desc,
                                        style: TextStyle(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 10),
                                      Obx(() {
                                        int quantity =
                                            productController.selectedProducts[productId] ?? 0;
                                        return quantity > 0
                                            ? Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 14),
                                          color: Colors.white,
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                onPressed: () =>
                                                    productController.addProduct(productId),
                                                icon: Icon(Icons.add,
                                                    color: Colors.lightBlueAccent),
                                              ),
                                              Text('$quantity'),
                                              IconButton(
                                                onPressed: () => productController
                                                    .removeProduct(productId),
                                                icon: Icon(Icons.remove,
                                                    color: Colors.lightBlueAccent),
                                              ),
                                            ],
                                          ),
                                        )
                                            : SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Obx(() {
            bool hasSelectedProduct = productController.hasselectedproduct();
            return Container(
              color: hasSelectedProduct ? Colors.blue : Colors.grey,
              width: double.infinity,
              height: 60,
              child: TextButton(
                onPressed: hasSelectedProduct
                    ? () {
                  Get.to(() => SelectingOrderType(userId: widget.userId));
                }
                    : null,
                child: Text(
                  hasSelectedProduct
                      ? AppLocalizations.of(context)!.proceed
                      : AppLocalizations.of(context)!.must_choose,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
