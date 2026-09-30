import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../helpers/db_helper.dart';

class ShopProvider with ChangeNotifier {
  List<Product> _products = [];
  List<CartItem> _cart = [];

  List<Product> get products => _products;
  List<CartItem> get cart => _cart;

  Future<void> fetchAndSetProducts() async {
    _products = await DBHelper.getProducts();
    await fetchAndSetCart();
    notifyListeners();
  }

  Future<void> fetchAndSetCart() async {
    _cart = await DBHelper.getCartItems();
    notifyListeners();
  }

  Future<void> addToCart(Product product) async {
    await DBHelper.insertOrUpdateCart(product);
    await fetchAndSetCart();
  }

  Future<void> updateQuantity(int cartId, int quantity) async {
    await DBHelper.updateQuantity(cartId, quantity);
    await fetchAndSetCart();
  }

  double get totalPrice {
    return _cart.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalItemCount {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }
}