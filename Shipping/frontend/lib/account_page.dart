import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoggedIn = false; 
  bool _isLoading = true; 
  String _userName = '';
  String _userEmail = '';

  final String _statusCheckUrl = 'http://localhost:8080/api/auth/check-status';

  @override
  void initState() {
    super.initState();
    _verifyUserWithServer();
  }

  // دالة المراقبة المستمرة والتحقق من السيرفر وتحديث الكاش
  Future<void> _verifyUserWithServer() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String email = prefs.getString('user_email') ?? '';

    // إذا لم يكن مسجلاً محلياً من الأساس
    if (!isLoggedIn || email.isEmpty) {
      _redirectToAuth();
      return;
    }

    try {
      // إرسال طلب فحص مباشر للسيرفر للتحقق من حالة الحساب وجلب أحدث البيانات
      final response = await http.post(
        Uri.parse(_statusCheckUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // إذا رد السيرفر بأن المستخدم غير موجود أو تم حظره
        if (data['success'] == false || data['is_banned'] == true) {
          await prefs.clear(); // مسح الكاش بالكامل
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حظر حسابك أو إزالته من النظام')),
            );
          }
          _redirectToAuth();
          return;
        }

        // استخراج أحدث بيانات المستخدم من استجابة السيرفر إن وجدت، أو الاعتماد على الكاش المحدث
        final Map<String, dynamic>? serverUser = data['user'];
        final String serverName = serverUser != null ? (serverUser['name'] ?? '') : '';
        
        if (serverName.isNotEmpty) {
          await prefs.setString('user_name', serverName);
        }

        final String finalName = serverName.isNotEmpty 
            ? serverName 
            : (prefs.getString('user_name') ?? 'مستخدم');

        setState(() {
          _isLoggedIn = true;
          _userName = finalName;
          _userEmail = email;
          _isLoading = false;
        });
      } else {
        // في حال فشل الاتصال بالسيرفر، نعتمد على الكاش الحالي بحذر
        _loadFromCacheLocally(prefs);
      }
    } catch (e) {
      // عند حدوث خطأ في الاتصال، نقوم بتحميل البيانات الموجودة في الكاش بحذر
      _loadFromCacheLocally(prefs);
    }
  }

  // دالة قراءة الكاش المحلي في حال انقطاع الاتصال بالسيرفر
  void _loadFromCacheLocally(SharedPreferences prefs) {
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (!isLoggedIn) {
      _redirectToAuth();
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _userName = prefs.getString('user_name') ?? 'مستخدم';
      _userEmail = prefs.getString('user_email') ?? 'غير متوفر'; // تم تصحيح الخطأ هنا
      _isLoading = false;
    });
  }

  // دالة مسح الكاش والانتقال لصفحة تسجيل الدخول
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // مسح الكاش بالكامل عند تسجيل الخروج
    _redirectToAuth();
  }

  void _redirectToAuth() {
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black87,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // عرض اسم المستخدم الحقيقي المحدث
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // عرض البريد الإلكتروني الحقيقي المحدث
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('إعدادات الحساب'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('طلبات الشحن'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('الأمان والخصوصية'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('حول التطبيق'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}