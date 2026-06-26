import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import 'package:google_fonts/google_fonts.dart';
import '../products/product_model.dart';
import '../cart/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('My Cart', style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/images/cart_bg_dark.jpg'
                : 'assets/images/cart_bg_light.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
            return RefreshIndicator(
              edgeOffset: 0,
              onRefresh: () => state.fetchProducts(),
              color: AppColors.forestGreen,
              child: state.cart.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 100,
                        ),
                        alignment: Alignment.center,
                        child: _buildEmptyState(context),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, 
                              left: 20, 
                              right: 20, 
                              bottom: 20
                            ),
                            itemCount: state.cart.length,
                            itemBuilder: (context, index) {
                              final cartItems = state.cart.entries.toList();
                              final entry = cartItems[index];
                              final cartKey = entry.key;
                              final parts = cartKey.split('_');
                              final productId = parts[0];
                              final variantName = parts.length > 1 ? parts[1] : null;

                              final products = state.products.where((p) => p.id == productId);
                              if (products.isEmpty) return const SizedBox.shrink();
                              
                              final product = products.first;
                               final quantity = entry.value;
                               final currentPrice = product.getPriceForQuantity(quantity, state.currentMode == AppMode.b2b, variantName);
                               final mrp = product.getMrp(variantName);
                               final isTiered = state.currentMode == AppMode.b2b && product.priceTiers.any((t) => quantity >= t.minQty);

                               return Container(
                                 margin: const EdgeInsets.only(bottom: 20),
                                 height: 140,
                                 decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(24),
                                   boxShadow: [
                                     BoxShadow(
                                       color: Colors.black.withValues(alpha: 0.1),
                                       blurRadius: 20,
                                       spreadRadius: 0,
                                       offset: const Offset(0, 8),
                                     ),
                                   ],
                                 ),
                                 child: ClipRRect(
                                   borderRadius: BorderRadius.circular(24),
                                   child: BackdropFilter(
                                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                     child: Container(
                                       color: AppColors.white.withValues(alpha: 0.7),
                                       child: Row(
                                         children: [
                                           Expanded(
                                             flex: 4,
                                             child: CachedNetworkImage(
                                               imageUrl: product.imageUrl,
                                               height: double.infinity,
                                               fit: BoxFit.cover,
                                             ),
                                           ),
                                           Expanded(
                                             flex: 6,
                                             child: Padding(
                                               padding: const EdgeInsets.all(16),
                                               child: Column(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                 children: [
                                                   Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                   const SizedBox(height: 4),
                                                   if (variantName != null && variantName.isNotEmpty) ...[
                                                     Container(
                                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                       decoration: BoxDecoration(
                                                         color: Colors.grey.shade200,
                                                         borderRadius: BorderRadius.circular(8),
                                                       ),
                                                       child: Text('Size: $variantName', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                                     ),
                                                     const SizedBox(height: 4),
                                                   ],
                                                   if (mrp > currentPrice)
                                                     Text('₹$mrp', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                                   Text('₹$currentPrice / ${(variantName != null && variantName.isNotEmpty) ? variantName : product.unit}', 
                                                        style: TextStyle(
                                                          color: isTiered ? AppColors.forestGreen : Theme.of(context).colorScheme.tertiary, 
                                                          fontSize: 14,
                                                          fontWeight: isTiered ? FontWeight.bold : FontWeight.normal
                                                        )),
                                                   const Spacer(),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => state.deleteFromCart(cartKey),
                                                        child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                                      ),
                                                      Row(
                                                        children: [
                                                          _QtyBtn(
                                                            icon: Icons.remove, 
                                                            onTap: () => state.removeFromCart(cartKey),
                                                            enabled: quantity > 1,
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                                            child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
                                                          ),
                                                          _QtyBtn(icon: Icons.add, onTap: () => state.addToCart(cartKey)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        _buildCheckoutSection(context, state),
                        const SizedBox(height: 100),
                      ],
                    ),
            );
          },
        ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, AppState state) {
    final double minBillAmount = state.minBillAmountB2B;
    final bool belowMinimum = state.cartTotal < minBillAmount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (belowMinimum) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Minimum bill ₹${minBillAmount.toStringAsFixed(0)} required. Add ₹${(minBillAmount - state.cartTotal).toStringAsFixed(2)} more.',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹${state.cartTotal.toStringAsFixed(2)}', 
                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary)),
                  ],
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: belowMinimum ? 0.5 : 1.0,
                  child: ElevatedButton(
                    onPressed: belowMinimum ? null : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      );
                    },
                    child: const Text('Checkout Now', style: TextStyle(color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_cart_outlined, 
                             size: 64, 
                             color: AppColors.forestGreen),
                ),
                const SizedBox(height: 32),
                const Text('Your cart is empty', 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                const SizedBox(height: 12),
                const Text('Looks like you haven\'t added anything yet.', 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: AppColors.lightText, fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _QtyBtn({required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
    );
  }
}
