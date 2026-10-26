import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int cartItemCount;
  final ValueChanged<String>? onSearchSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCartPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onGridPressed; 
  final ValueChanged<String>? onCountryChanged; 
  final VoidCallback? onLogoIconPressed;
  final VoidCallback? onSearchButtonPress;
  final String selectedCountryUrl;

  const Header({
    Key? key,
    required this.title,
    this.cartItemCount = 0,
    this.onSearchSubmitted,
    this.onChanged,
    this.onCartPressed,
    this.onProfilePressed,
    this.onMenuPressed,
    this.onGridPressed,
    this.onCountryChanged,
    this.onLogoIconPressed,
    this.onSearchButtonPress,
    this.selectedCountryUrl = 'https://flagcdn.com/w320/dz.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    final List<Map<String, String>> countries = [
      {'name': 'الجزائر', 'url': 'https://flagcdn.com/w320/dz.png'},
      {'name': 'المملكة العربية السعودية', 'url': 'https://flagcdn.com/w320/sa.png'},
      {'name': 'فرنسا', 'url': 'https://flagcdn.com/w320/fr.png'},
      {'name': 'الولايات المتحدة', 'url': 'https://flagcdn.com/w320/us.png'},
      {'name': 'الصين', 'url': 'https://flagcdn.com/w320/cn.png'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. [أقصى اليمين]: الشعار
          Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuPressed,
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.check, color: Colors.orange, size: 20),
                onPressed: onLogoIconPressed ?? () {},
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // 2. [المنتصف]: شريط البحث الحي (Live Search)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: onChanged,
                        onSubmitted: onSearchSubmitted,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن المنتجات...',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'هدية مجانية 0.00',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.qr_code_scanner, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                      ],
                    ),
                    GestureDetector(
                      onTap: onSearchButtonPress,
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(22),
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. [أقصى اليسار]: السلة، الحساب، الأعلام
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 24),
                    tooltip: 'سلة المشتريات',
                    onPressed: onCartPressed ?? () {},
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              
              // زر الحساب
              IconButton(
                icon: const Icon(Icons.person_outline, size: 24),
                tooltip: 'حسابي',
                onPressed: onProfilePressed ?? () {},
              ),
              
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: selectedCountryUrl,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                tooltip: 'اختر الدولة',
                onSelected: (String url) {
                  if (onCountryChanged != null) {
                    onCountryChanged!(url);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return countries.map((country) {
                    return PopupMenuItem<String>(
                      value: country['url'],
                      child: Row(
                        children: [
                          Image.network(
                            country['url']!,
                            width: 24,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(country['name']!, style: const TextStyle(fontSize: 14, color: Colors.black)),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                        selectedCountryUrl,
                        width: 22,
                        height: 15,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 18),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 24),
                tooltip: 'الأقسام والتطبيقات',
                onPressed: onGridPressed ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}