import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'account_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoginMode = true; 
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final String _baseUrl = 'http://localhost:8080/api/auth';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    
    // 1. فحص الحقول الفارغة
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }

    // 2. فحص صحة البريد الإلكتروني (يحتوي على @ وينتهي بـ .com)
    if (!email.contains('@') || !email.endsWith('.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('البريد الإلكتروني غير صالح، يجب أن يحتوي على @ وينتهي بـ .com')),
      );
      return;
    }

    // 3. فحص طول كلمة المرور (أكبر من 8 أحرف)
    if (password.length <= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور يجب أن تكون أكثر من 8 أحرف')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        // --- طلب تسجيل الدخول (Login API) ---
        final response = await http.post(
          Uri.parse('$_baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );

        if (response.body.isEmpty) {
          throw Exception('استجابة السيرفر فارغة');
        }

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          final String adminSecret = data['admin_secret'] ?? '';
          final Map<String, dynamic>? user = data['user'];
          
          final String userName = user != null ? (user['name'] ?? 'مستخدم') : 'مستخدم';
          final String userEmail = user != null ? (user['email'] ?? email) : email;

          final prefs = await SharedPreferences.getInstance();
          
          // مسح أي بيانات سابقة تماماً لمنع تداخل الأسماء والكاش القديم
          await prefs.clear();

          // حفظ البيانات الجديدة الخاصة بالمستخدم الحالي
          await prefs.setString('admin_token', adminSecret);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_name', userName);
          await prefs.setString('user_email', userEmail);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'تم تسجيل الدخول بنجاح')),
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AccountPage()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'خطأ في تسجيل الدخول')),
          );
        }

      } else {
        // --- طلب إنشاء حساب جديد (Sign Up API) ---
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء إدخال الاسم الكامل')),
          );
          setState(() { _isLoading = false; });
          return;
        }

        // إرسال البيانات بشكل آمن بدون إرسال id أو is_admin لحماية التطبيق من ثغرة الحقن
        final response = await http.post(
          Uri.parse('$_baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        );

        if (response.body.isEmpty) {
          throw Exception('استجابة السيرفر فارغة');
        }

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح، يمكنك تسجيل الدخول الآن')),
          );
          setState(() {
            _isLoginMode = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'فشل إنشاء الحساب')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الاتصال بالسيرفر: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoginMode ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_person_outlined,
                  size: 80,
                  color: Colors.black,
                ),
                const SizedBox(height: 24),
                Text(
                  _isLoginMode ? 'أهلاً بك مجدداً!' : 'أنشئ حسابك الآن',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode 
                      ? 'سجل دخولك للمتابعة إلى متجر الشحن' 
                      : 'سجل بياناتك للبدء في استخدام كافة مميزات المتجر',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                if (!_isLoginMode) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني (مثال: example@domain.com)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور (أكثر من 8 أحرف)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'تسجيل الدخول' : 'إنشاء الحساب',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                    });
                  },
                  child: Text(
                    _isLoginMode 
                        ? 'ليس لديك حساب؟ انقر هنا لإنشاء حساب جديد' 
                        : 'لديك حساب بالفعل؟ انقر هنا لتسجيل الدخول',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}