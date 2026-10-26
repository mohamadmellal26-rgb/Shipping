import 'package:flutter/material.dart';
import 'product_grid.dart'; // لتضمين ProductModel

class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;
  final Function(ProductModel product)? onAddToCart;

  const ProductDetailsPage({
    Key? key,
    required this.product,
    this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48.0 : 16.0, vertical: 16.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildImageGallery(product)),
                  const SizedBox(width: 32),
                  Expanded(flex: 6, child: _buildProductInfo(product)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(product),
                  const SizedBox(height: 24),
                  _buildProductInfo(product),
                ],
              ),
      ),
    );
  }

  Widget _buildImageGallery(ProductModel product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.images.length > 1) ...[
          SizedBox(
            width: 70,
            height: 400,
            child: ListView.builder(
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        product.images[index],
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Container(
            height: 420,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.images.isNotEmpty ? product.images[_selectedImageIndex] : product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildTag('Savings', Colors.orange),
              const Text('✓ Free shipping', style: TextStyle(fontSize: 12, color: Colors.black87)),
              const Text('✓ 135 DA Credit for delay', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              'Arrives in DZ in as little as 5 business days after shipment',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(product.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 8),
            Text('4.1K+ sold', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'DA ${product.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(width: 12),
            Text(
              'DA ${(product.price * 1.5).toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text('52% OFF', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLEARANCE DEAL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('ENDS IN 07:01:02:10', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Style: Axolotl', style: TextStyle(fontWeight: FontWeight.w500)),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade600),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Qty', style: TextStyle(fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                      ),
                      Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            onPressed: () {
              if (widget.onAddToCart != null) {
                widget.onAddToCart!(product);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تمت إضافة ${product.title} إلى السلة بنجاح'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Add to cart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}