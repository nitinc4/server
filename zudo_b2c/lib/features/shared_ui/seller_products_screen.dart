import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../products/product_model.dart';
import '../products/product_details_screen.dart';

class SellerProductsScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const SellerProductsScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          sellerName,
          style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final products = state.products.where((p) {
            return p.sellerId == sellerId;
          }).toList();

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 64, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No products listed by this seller yet.',
                    style: TextStyle(color: AppColors.lightText, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _SellerProductCard(product: products[index]);
            },
          );
        },
      ),
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final Product product;

  const _SellerProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final inWishlist = state.isInWishlist(product.id);
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Hero(
                          tag: 'product_seller_${product.id}',
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => state.toggleWishlist(product),
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                            radius: 16,
                            child: Icon(
                              inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                              size: 18, 
                              color: inWishlist ? AppColors.error : Theme.of(context).colorScheme.tertiary
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.subCategory,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.lightText, fontSize: 11),
                      ),
                      if (product.variants.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Sizes: ${product.variants.map((v) => v.sizeName).join(", ")}',
                          style: TextStyle(
                            color: AppColors.forestGreen.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      _StockBadge(stock: product.variants.isNotEmpty ? product.variants.first.stock : product.stock),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.currentMode == AppMode.b2b && (!state.isB2BVerified || state.isWaitingApproval))
                                  Text(
                                    'Price shown post verification',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.orange.shade800,
                                    ),
                                  )
                                else ...[
                                  if (product.getMrp() > product.getPriceForQuantity(1, state.currentMode == AppMode.b2b))
                                    Text(
                                      '₹${product.getMrp()}',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.lightText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    '₹${product.getPriceForQuantity(1, state.currentMode == AppMode.b2b)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                  ),
                                ],
                                if (state.currentMode == AppMode.b2b)
                                  Text(
                                    'Min. Bill: ₹2,000',
                                    style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          if (!(state.currentMode == AppMode.b2b && (!state.isB2BVerified || state.isWaitingApproval)))
                          Builder(
                            builder: (context) {
                              final cartKey = product.variants.isNotEmpty
                                  ? '${product.id}_${product.variants.first.sizeName}'
                                  : product.id;
                              final int cartQty = state.cart[cartKey] ?? 0;
                              final int maxStock = product.variants.isNotEmpty ? product.variants.first.stock : product.stock;

                              if (cartQty > 0) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.tertiary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => state.removeFromCart(cartKey),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      Text(
                                        cartQty.toString(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      GestureDetector(
                                        onTap: cartQty < maxStock ? () => state.addToCart(cartKey) : null,
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(Icons.add_rounded, color: cartQty < maxStock ? Colors.white : Colors.white54, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: maxStock > 0 ? () {
                                  state.addToCart(cartKey);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } : null,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: maxStock > 0
                                      ? Theme.of(context).colorScheme.tertiary
                                      : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.add_rounded, color: maxStock > 0 ? AppColors.white : Colors.grey.shade500, size: 20),
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;

    if (stock <= 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = 'Out of Stock';
    } else if (stock <= 5) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      label = 'Only $stock left!';
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      label = '$stock in stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
