import 'dart:convert';
import 'dart:math';

import 'package:ecommercefood/data/database.dart';
import 'package:ecommercefood/modules/models/Category.dart';
import 'package:ecommercefood/modules/models/Product.dart';
import 'package:ecommercefood/modules/models/ShoppingCart.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class StateController extends ChangeNotifier {
  List<Product> listProducts = [];
  ShoppingCart shoppingCart = ShoppingCart();
  

  final _baseUrl =
      'https://ecommerce-mini-projeto-04-default-rtdb.firebaseio.com';

  void addItem(Product product) {
    listProducts.add(product);
    notifyListeners();
  }

  void removeItem(Product product) {
    listProducts.remove(product);
    notifyListeners();
  }

  int get totalItens {
    return listProducts.length;
  }

  List<Product> getProducts() {
    return getProductsFirebase();
  }

  List<Product> getProductsFirebase() {
    // get products of firebase
    http.get(Uri.parse(_baseUrl + '/products.json')).then((response) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<Product> loadedProducts = [];
      data.forEach((id, prod) {
        loadedProducts.add(Product(
          id: id,
          name: prod['title'],
          description: prod['description'],
          price: prod['price'].toDouble(),
          imageUrl: prod['imageUrl'],
          isFavorite: prod['isFavorite'],          
          categoryId: prod['category'],
        ));
      });
      listProducts.clear();
      listProducts.addAll(loadedProducts);
      print("aqui");
      notifyListeners();
    });
    return [...listProducts];
  }

  List<Product> getProductsShopping() {
    return shoppingCart.getProductsShopping();
  }

  List<Product> getFavoriteProducts() {
    return getProducts().where((p) => p.isFavorite).toList();
  }

  toggleFavorite(Product product) {
    product.toggleFavorite();
    notifyListeners();
  }

  Future<void> addProduct(Product product) {
    return postFirebase(product).then((response) {
      final id = jsonDecode(response.body)['name'];
      product.id = id;
      listProducts.add(product);
      notifyListeners();
    }).catchError((error) {
      print(error);
    });
  }

  Future<void> saveProduct(Map<String, Object> data) {
    bool hasId = data['id'] != null;

    final product = Product(
      id: hasId ? data['id'] as String : Random().nextDouble().toString(),
      name: data['title'] as String,
      description: data['description'] as String,
      price: data['price'] as double,
      imageUrl: data['imageUrl'] as String,
      categoryId: int.parse(data['category'] as String),
    );

    if (hasId) {
      return updateProduct(product);
    } else {
      return addProduct(product);
    }
  }

  Category getCategory(int index) {
    return DatabaseProducts.getListCategoriesOrderByTitle()[index];
  }

  void updateProductList(Product product) {
    final index = listProducts.indexWhere((prod) => prod.id == product.id);
    if (index >= 0) {
      listProducts[index] = product;
    }
    notifyListeners();
  }

  Future<void> updateProduct(Product product) {
    int index = listProducts.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      listProducts[index] = product;
      updateProductInFirebase(product).then((_) {
        notifyListeners();
      }).catchError((e) {
        print(e);
      });
    }
    return Future.value();
  }

  Future<void> updateProductInFirebase(Product product) {
    final url = '$_baseUrl/products/${product.id}.json';
    return http.patch(
      Uri.parse(url),
      body: jsonEncodeProduct(product),
    );
  }

  void removeProduct(Product product) {
    int index = listProducts.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      listProducts.removeWhere((p) => p.id == product.id);
      removeProductInFirebase(product).then((_) {
        notifyListeners();
      }).catchError((e) {
        print(e);
      });
    }
  }

  Future<void> removeProductInFirebase(Product product) {
    final url = '$_baseUrl/products/${product.id}.json';
    return http.delete(Uri.parse(url));
  }

  Future<http.Response> postFirebase(Product product) {
    return http.post(
      Uri.parse('$_baseUrl/products.json'),
      body: jsonEncodeProduct(product),
    );
  }

  String jsonEncodeProduct(Product product) {
    return jsonEncode({
        "title": product.name,
        "description": product.description,
        "price": product.price,
        "imageUrl": product.imageUrl,
        "isFavorite": product.isFavorite,
        "category": product.categoryId,
      });
  }
}
