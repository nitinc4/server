import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import 'product_model.dart';
import 'product_reviews_section.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? selectedVariant;
  Product get product => widget.product;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      selectedVariant = widget.product.variants.first.sizeName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Consumer<AppState>(
      builder: (context, state, child) {
        final bool isB2B = state.currentMode == AppMode.b2b;
        final String cartKey = selectedVariant != null ? '${product.id}_$selectedVariant' : product.id;
        final int cartQty = state.cart[cartKey] ?? 0;
        final double displayPrice = product.getPriceForQuantity(cartQty, isB2B, selectedVariant);
        final int displayStock = (selectedVariant != null && product.variants.isNotEmpty)
            ? product.variants.firstWhere((v) => v.sizeName == selectedVariant, orElse: () => product.variants.first).stock
            : product.stock;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, state),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceAndRating(context, state, displayPrice, selectedVariant),
                      const SizedBox(height: 16),
                      
                      if (product.variants.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Select Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: product.variants.map((v) {
                            final isSelected = selectedVariant == v.sizeName;
                            return ChoiceChip(
                              label: Text(v.sizeName),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    selectedVariant = v.sizeName;
                                  });
                                }
                              },
                              selectedColor: AppColors.forestGreen.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.forestGreen : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTitleAndCategory(context, displayStock),
                      const SizedBox(height: 24),
                      if (isB2B) ...[
                        _buildMinBillBadge(context),
                        const SizedBox(height: 24),
                        _buildTieredPricingTable(context),
                        const SizedBox(height: 24),
                      ],
                      _buildDescription(),
                      const Divider(height: 32),
                      ProductReviewsSection(productId: product.id),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: _buildBottomBar(context, state, displayStock),
        );
      },
    );
  }

  Widget _buildTieredPricingTable(BuildContext context) {
    if (product.priceTiers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bulk Pricing Tiers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.sand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sand.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity', style: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold)),
                    const Text('Price per Unit', style: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...product.priceTiers.map((tier) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tier.minQty}+ ${(selectedVariant != null && selectedVariant!.isNotEmpty) ? selectedVariant : widget.product.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${tier.price}',
                        style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, AppState state) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            state.isInWishlist(product.id) ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: state.isInWishlist(product.id) ? Colors.red : AppColors.darkText,
          ),
          onPressed: () => state.toggleWishlist(product),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${product.id}',
          child: CachedNetworkImage(
            imageUrl: product.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.sand.withValues(alpha: 0.2)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceAndRating(BuildContext context, AppState state, double displayPrice, String? selectedVariantName) {
    double mrp = product.getMrp(selectedVariantName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.currentMode == AppMode.b2b && (!state.isB2BVerified || state.isWaitingApproval))
              Text(
                'Price shown post verification',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
              )
            else ...[
              if (mrp > displayPrice)
                Text(
                  '₹$mrp',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.lightText,
                    fontSize: 16,
                  ),
                ),
              Text(
                '₹$displayPrice',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.forestGreen,
                    ),
              ),
              if (product.getNormalizedPriceString(displayPrice, selectedVariantName).isNotEmpty)
                Text(
                  product.getNormalizedPriceString(displayPrice, selectedVariantName),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.sand.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                product.rating.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndCategory(BuildContext context, int displayStock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (product.sellerName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Sold by: ${product.sellerName}',
            style: TextStyle(
              color: AppColors.forestGreen.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${product.category} • ${product.subCategory} • ${product.unit}',
          style: const TextStyle(color: AppColors.lightText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _StockAvailabilityBadge(stock: displayStock),
      ],
    );
  }

  Widget _buildMinBillBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minimum Bill Amount',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
              ),
              const Text(
                'Cart total must be at least \u20b92,000',
                style: TextStyle(color: AppColors.lightText, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Description',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        const Text(
          'Our premium quality products are sourced directly from sustainable farms. We ensure the highest standards of hygiene and quality control from farm to your kitchen.',
          style: TextStyle(color: AppColors.lightText, height: 1.6, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, AppState state, int displayStock) {
    final String cartKey = selectedVariant != null ? '${product.id}_$selectedVariant' : product.id;
    final bool inCart = state.cart.containsKey(cartKey);
    final bool outOfStock = displayStock <= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: state.currentMode == AppMode.b2b && (!state.isB2BVerified || state.isWaitingApproval)
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Account verification in progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : outOfStock
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Out of Stock',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              : Row(
              children: [
                if (inCart) ...[
                  _buildQuantitySelector(state, cartKey),
                  const SizedBox(width: 24),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      state.addToCart(cartKey);
                      if (!inCart) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(inCart ? 'Add More' : 'Add to Cart'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuantitySelector(AppState state, String cartKey) {
    final int quantity = state.cart[cartKey] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sand.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, color: AppColors.forestGreen),
            onPressed: () => state.removeFromCart(cartKey),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.forestGreen),
            onPressed: () => state.addToCart(cartKey),
          ),
        ],
      ),
    );
  }
}

class _StockAvailabilityBadge extends StatelessWidget {
  final int stock;
  const _StockAvailabilityBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;
    final IconData icon;

    if (stock <= 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = 'Out of Stock';
      icon = Icons.remove_circle_outline_rounded;
    } else if (stock <= 5) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      label = 'Only $stock left!';
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      label = '$stock units available';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
