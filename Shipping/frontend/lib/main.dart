import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Header.dart';
import 'categories_bar.dart';
import 'product_grid.dart';
import 'product_details_page.dart';
import 'account_page.dart';
import 'cart_page.dart';
import 'auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipping Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'shopping'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _cartCount = 0;
  final List<CartItem> _cartItems = [];
  late Future<List<ProductModel>> _futureProducts;
  String _selectedCategory = 'كل الأصناف';
  String _searchQuery = '';
  
  bool _isBanned = false;
  bool _isCheckingBan = true;

  // متغيرات حفظ بيانات المستخدم الحالي من SharedPreferences
  String _userId = '';
  String _userEmail = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCheckBan();
    _futureProducts = fetchProductsFromGoBackend();
  }

  // دالة تحميل بيانات المستخدم وفحص ما إذا كان محظوراً من السيرفر
  Future<void> _loadUserDataAndCheckBan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _userName = prefs.getString('user_name') ?? 'مستخدم';

      if (_userEmail.isNotEmpty) {
        final response = await http.post(
          Uri.parse('http://localhost:8080/api/auth/check-status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': _userEmail}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['is_banned'] == true) {
            setState(() {
              _isBanned = true;
            });
          }
        }
      }
    } catch (e) {
      print('خطأ أثناء فحص الحظر: $e');
    } finally {
      setState(() {
        _isCheckingBan = false;
      });
    }
  }

  Future<List<ProductModel>> fetchProductsFromGoBackend() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/api/products'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(utf8.decode(response.bodyBytes));
        List<ProductModel> products = body.map((item) {
          List<String> imgList = (item['images'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          return ProductModel(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'بدون عنوان',
            price: (item['price'] as num?)?.toDouble() ?? 0.0,
            rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
            category: item['category']?.toString() ?? 'أخرى',
            images: imgList,
          );
        }).toList();
        return products;
      } else {
        throw Exception('فشل الاتصال بالسيرفر');
      }
    } catch (e) {
      throw Exception('تأكد من تشغيل سيرفر الـ Go:\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingBan) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_isBanned) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 90, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'تم حظر حسابك بالكامل',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'عذراً، لا يمكنك استخدام المتجر أو إتمام الطلبات لأن حسابك محظور من قبل الإدارة.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                    }
                  },
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: Header(
        title: widget.title,
        cartItemCount: _cartCount,
        onProfilePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountPage(),
            ),
          );
        },
        onCartPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartPage(
                cartItems: _cartItems,
                userId: _userId,       // تمرير معرف المستخدم المسجل
                userEmail: _userEmail, // تمرير بريد المستخدم المسجل
                userName: _userName,   // تمرير اسم المستخدم المسجل
                onRemoveItem: (item) {
                  setState(() {
                    _cartItems.remove(item);
                    _cartCount = _cartItems.fold(0, (sum, i) => sum + i.quantity);
                  });
                },
                onUpdateQuantity: (item, newQuantity) {
                  setState(() {
                    item.quantity = newQuantity;
                    _cartCount = _cartItems.fold(0, (sum, i) => sum + i.quantity);
                  });
                },
                onClearCart: () {
                  setState(() {
                    _cartItems.clear();
                    _cartCount = 0;
                  });
                },
              ),
            ),
          ).then((_) {
            setState(() {
              _cartCount = _cartItems.fold(0, (sum, i) => sum + i.quantity);
            });
          });
        },
        onChanged: (query) {
          setState(() {
            _searchQuery = query.trim();
          });
        },
        onSearchSubmitted: (query) {
          setState(() {
            _searchQuery = query.trim();
          });
        },
      ),
      body: Column(
        children: [
          CategoriesBar(
            onCategorySelected: (categoryName) {
              setState(() {
                _selectedCategory = categoryName;
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('لا توجد منتجات متاحة حالياً'),
                  );
                }

                List<ProductModel> allProducts = snapshot.data!;

                List<ProductModel> filteredProducts = _selectedCategory == 'كل الأصناف'
                    ? allProducts
                    : allProducts.where((p) => p.category == _selectedCategory).toList();

                if (_searchQuery.isNotEmpty) {
                  filteredProducts = filteredProducts
                      .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('لا توجد منتجات مطابقة لبحثك حالياً'),
                  );
                }

                return ProductGrid(
                  products: filteredProducts,
                  onAddToCart: (product) {
                    setState(() {
                      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
                      if (existingIndex >= 0) {
                        _cartItems[existingIndex].quantity++;
                      } else {
                        _cartItems.add(CartItem(product: product, quantity: 1));
                      }
                      _cartCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);
                    });
                  },
                  onProductTap: (product) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(
                          product: product,
                          onAddToCart: (p) {
                            setState(() {
                              final existingIndex = _cartItems.indexWhere((item) => item.product.id == p.id);
                              if (existingIndex >= 0) {
                                _cartItems[existingIndex].quantity++;
                              } else {
                                _cartItems.add(CartItem(product: p, quantity: 1));
                              }
                              _cartCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}