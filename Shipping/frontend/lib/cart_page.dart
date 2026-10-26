import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'product_grid.dart'; // تأكد من استيراد نموذج ProductModel أو تعديله حسب مشروعك

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onRemoveItem;
  final Function(CartItem, int) onUpdateQuantity;
  final VoidCallback? onClearCart;
  final String userId;    // معرف المستخدم المستلم من التوكن أو تسجيل الدخول
  final String userEmail; // البريد الإلكتروني المستلم من التوكن أو تسجيل الدخول
  final String userName;  // اسم المستخدم المسجل

  const CartPage({
    Key? key,
    this.cartItems = const [],
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    this.onClearCart,
    required this.userId,
    required this.userEmail,
    required this.userName,
  }) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isCheckingOut = false;

  final String _checkoutUrl = 'http://localhost:8080/api/orders/create';

  // تم حذف _nameController لعدم الحاجة لإدخال الاسم يدوياً
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  
  // خريطة الدول ومدنها الحقيقية بشكل كامل
  String _selectedCountry = 'الجزائر';
  String? _selectedCityOrState;

  final Map<String, List<String>> _countriesAndRegions = {
    'الجزائر': [
      '01 - أدرار', '02 - الشلف', '03 - الأغواط', '04 - أم البواقي', '05 - باتنة',
      '06 - بجاية', '07 - بسكرة', '08 - بشار', '09 - البليدة', '10 - البويرة',
      '11 - تمنراست', '12 - تبسة', '13 - تلمسان', '14 - تيارت', '15 - تيزي وزو',
      '16 - الجزائر العاصمة', '17 - الجلفة', '18 - جيجل', '19 - سطيف', '20 - سعيدة',
      '21 - سكيكدة', '22 - سيدي بلعباس', '23 - عنابة', '24 - قالمة', '25 - قسنطينة',
      '26 - المدية', '27 - مستغانم', '28 - المسيلة', '29 - معسكر', '30 - ورقلة',
      '31 - وهران', '32 - البيض', '33 - إليزي', '34 - برج بوعريريج', '35 - بومرداس',
      '36 - الطارف', '37 - تندوف', '38 - تيسمسيلت', '39 - الوادي', '40 - خنشلة',
      '41 - سوق أهراس', '42 - تيبازة', '43 - ميلة', '44 - عين الدفلى', '45 - نعامة',
      '46 - عين تموشنت', '47 - غرداية', '48 - غليزان', '49 - المغير', '50 - المنيعة',
      '51 - أولاد جلال', '52 - برج باجي مختار', '53 - بني عباس', '54 - تنظوف', '55 - توقرت',
      '56 - جانت', '57 - المغير', '58 - المنيعة'
    ],
    'فرنسا': [
      'باريس (Paris)', 'مارسيليا (Marseille)', 'ليون (Lyon)', 'تولوز (Toulouse)', 
      'نيس (Nice)', 'نانت (Nantes)', 'ستراسبورغ (Strasbourg)', 'مونبلييه (Montpellier)', 
      'بوردو (Bordeaux)', 'ليل (Lille)', 'رين (Rennes)', 'ريمس (Reims)'
    ],
    'إسبانيا': [
      'مدريد (Madrid)', 'برشلونة (Barcelona)', 'فالنسيا (Valencia)', 'إشبيلية (Seville)', 
      'سرقسطة (Zaragoza)', 'مالقة (Malaga)', 'مرسية (Murcia)', 'بلباو (Bilbao)', 
      'أليكانتي (Alicante)', 'قرطبة (Cordoba)'
    ],
    'الولايات المتحدة الأمريكية': [
      'نيويورك (New York)', 'لوس أنجلوس (Los Angeles)', 'شيكاغو (Chicago)', 'هيوستن (Houston)', 
      'فينيكس (Phoenix)', 'فيلادلفيا (Philadelphia)', 'سان أنтониيو (San Antonio)', 'سان دييغو (San Diego)', 
      'دالاس (Dallas)', 'سان خوسيه (San Jose)', 'واشنطن العاصمة (Washington, D.C.)', 'ميامي (Miami)'
    ],
  };

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(double totalPrice) async {
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final area = _areaController.text.trim();
    final state = _selectedCityOrState;

    if (address.isEmpty || phone.isEmpty || state == null || state.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة كافة حقول الشحن الإجبارية واختيار الولاية/المدينة')),
      );
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      String productsSummary = widget.cartItems.map((item) => '${item.product.title} (x${item.quantity})').join(', ');

      final response = await http.post(
        Uri.parse(_checkoutUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': widget.userId,       // إرسال معرف المستخدم من التوكن
          'customer_email': widget.userEmail, // إرسال البريد الإلكتروني للتأكد من الحظر
          'customer_name': widget.userName,   // إرسال اسم المستخدم تلقائياً
          'product_name': productsSummary,
          'quantity': widget.cartItems.fold(0, (sum, item) => sum + item.quantity),
          'product_price': totalPrice,
          'total_amount': totalPrice,
          'address': address,
          'phone': phone,
          'area': area,
          'state': state,
          'country': _selectedCountry,
          'payment_method': 'الدفع عند الاستلام',
        }),
      );

      if (response.body.isEmpty) {
        throw Exception('استجابة السيرفر فارغة');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'تم تأكيد الطلب بنجاح')),
        );

        if (widget.onClearCart != null) {
          widget.onClearCart!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'فشل تأكيد الطلب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الاتصال بالسيرفر: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  void _showCheckoutDialog(double totalPrice) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final List<String> currentRegions = _countriesAndRegions[_selectedCountry] ?? [];

          return AlertDialog(
            title: const Text('تفاصيل الشحن (الدفع عند الاستلام)', style: TextStyle(fontSize: 15)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عرض اسم المستخدم الحالي كمعلومة توضيحية بدل خانة الإدخال
                  Text(
                    'الطلب باسم: ${widget.userName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'العنوان بالتفصيل (الشارع، رقم المبنى)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'المنطقة / الحي'),
                  ),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedCountry,
                    decoration: const InputDecoration(labelText: 'الدولة'),
                    items: _countriesAndRegions.keys.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedCountry = value!;
                        _selectedCityOrState = null; 
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _selectedCityOrState,
                    decoration: InputDecoration(
                      labelText: _selectedCountry == 'الجزائر' ? 'اختر الولاية' : 'اختر المدينة / المقاطعة',
                    ),
                    isExpanded: true,
                    items: currentRegions.map((region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedCityOrState = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: _isCheckingOut ? null : () => _submitOrder(totalPrice),
                child: _isCheckingOut
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأكيد الشراء'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartItems;

    double totalPrice = items.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سلة المشتريات',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'سلة المشتريات فارغة حالياً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أضف بعض المنتجات للبدء في التسوق',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.product.images.isNotEmpty
                                  ? Image.network(
                                      item.product.images.first,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image, size: 50, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${item.product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      widget.onUpdateQuantity(item, item.quantity - 1);
                                      setState(() {});
                                    } else {
                                      widget.onRemoveItem(item);
                                      setState(() {});
                                    }
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    widget.onUpdateQuantity(item, item.quantity + 1);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                              onPressed: () {
                                widget.onRemoveItem(item);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المجموع الكلي:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _showCheckoutDialog(totalPrice),
                          child: const Text(
                            'إتمام الطلب والدفع عند الاستلام',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}