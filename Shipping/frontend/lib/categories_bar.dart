import 'package:flutter/material.dart';

class CategoriesBar extends StatelessWidget implements PreferredSizeWidget {
  final Function(String categoryName)? onCategorySelected;

  const CategoriesBar({Key? key, this.onCategorySelected}) : super(key: key);

  final List<Map<String, dynamic>> categories = const [
    {'name': 'كل الأصناف', 'icon': Icons.menu},
    {'name': 'السيارات', 'icon': Icons.directions_car_outlined},
    {'name': 'عروض السوبر', 'icon': Icons.local_offer_outlined, 'isSpecial': true},
    {'name': 'Choice', 'icon': Icons.thumb_up_outlined},
    {'name': 'AliExpress Business', 'icon': Icons.business_center_outlined},
    {'name': 'أجهزة', 'icon': Icons.devices},
    {'name': 'ملابس نسائية', 'icon': Icons.woman},
    {'name': 'ملابس رجالية', 'icon': Icons.man},
    {'name': 'أثاث', 'icon': Icons.chair_outlined},
    {'name': 'أكثر', 'icon': Icons.keyboard_arrow_down},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final bool isSpecial = cat['isSpecial'] == true;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ActionChip(
              avatar: Icon(
                cat['icon'],
                size: 16,
                color: isSpecial ? Colors.brown : Colors.black87,
              ),
              label: Text(
                cat['name'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
                  color: isSpecial ? Colors.brown : Colors.black87,
                ),
              ),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                if (onCategorySelected != null) {
                  onCategorySelected!(cat['name']);
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50.0);
}