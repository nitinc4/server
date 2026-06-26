import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../products/product_model.dart';
import '../products/product_details_screen.dart';
import '../products/category_model.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import 'seller_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Explore',
          style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          // Dynamic compilation of unique sellers
          final uniqueSellersMap = <String, String>{};
          for (var p in state.products) {
            if (p.sellerId != null && p.sellerName != null && p.sellerId!.isNotEmpty && p.sellerName!.isNotEmpty) {
              uniqueSellersMap[p.sellerId!] = p.sellerName!;
            }
          }
          final sellersList = uniqueSellersMap.entries.toList();

          return Column(
            children: [
              // Glassmorphic / Premium Sliding Tab Selector styled like the bottom navigation bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Theme.of(context).colorScheme.tertiary,
                    unselectedLabelColor: AppColors.lightText,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Categories'),
                      Tab(text: 'Sellers'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. CATEGORIES TAB
                    RefreshIndicator(
                      onRefresh: () => state.fetchCategories(),
                      color: AppColors.forestGreen,
                      child: (state.isLoading && state.categories.isEmpty)
                          ? const Center(child: CircularProgressIndicator())
                          : state.categories.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: const Center(child: Text('No categories available')),
                                  ),
                                )
                              : GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                    bottom: 120,
                                  ),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: state.categories.length,
                                  itemBuilder: (context, index) {
                                    final category = state.categories[index];
                                    return GestureDetector(
                                      onTap: () {
                                        if (category.subCategories.isEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CategoryProductsScreen(
                                                categoryName: category.name,
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SubCategoriesScreen(category: category),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              if (category.imageUrl.isNotEmpty)
                                                CachedNetworkImage(
                                                  imageUrl: category.imageUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                                                  errorWidget: (context, url, error) => const Icon(Icons.category_outlined, size: 40),
                                                )
                                              else
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.category_outlined, size: 40),
                                                ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 16,
                                                left: 16,
                                                right: 16,
                                                child: Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    // 2. SELLERS TAB
                    RefreshIndicator(
                      onRefresh: () => state.fetchProducts(),
                      color: AppColors.forestGreen,
                      child: state.isLoading && sellersList.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : sellersList.isEmpty
                              ? SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.storefront_rounded, size: 64, color: AppColors.grey),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'No active sellers found',
                                            style: TextStyle(color: AppColors.lightText, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    left: 20,
                                    right: 20,
                                    bottom: 120,
                                  ),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.95,
                                  ),
                                  itemCount: sellersList.length,
                                  itemBuilder: (context, index) {
                                    final sellerEntry = sellersList[index];
                                    final sellerId = sellerEntry.key;
                                    final sellerName = sellerEntry.value;
                                    
                                    // Count seller products
                                    final productCount = state.products.where((p) => p.sellerId == sellerId).length;

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SellerProductsScreen(
                                              sellerId: sellerId,
                                              sellerName: sellerName,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardTheme.color ?? Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: AppColors.forestGreen.withValues(alpha: 0.1),
                                              child: Icon(
                                                Icons.store_rounded,
                                                size: 32,
                                                color: AppColors.forestGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              sellerName,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$productCount items listed',
                                              style: TextStyle(
                                                color: AppColors.lightText,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SubCategoriesScreen extends StatelessWidget {
  final CategoryItem category;

  const SubCategoriesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(category.name, style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: category.subCategories.isEmpty
        ? const Center(child: Text('No subcategories available'))
        : GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: category.subCategories.length,
            itemBuilder: (context, index) {
              final subCat = category.subCategories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(subCategory: subCat.name)));
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (subCat.imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: subCat.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => const Icon(Icons.subdirectory_arrow_right, size: 40),
                          )
                        else
                          Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.subdirectory_arrow_right, size: 40),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            subCat.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  final String? subCategory;
  final String? categoryName;

  const CategoryProductsScreen({super.key, this.subCategory, this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(subCategory ?? categoryName ?? 'Products', style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final products = state.products.where((p) {
            if (subCategory != null) {
              return p.subCategory == subCategory;
            }
            if (categoryName != null) {
              return p.category == categoryName;
            }
            return false;
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text('No products found'));
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
              return _CategoryProductCard(product: products[index]);
            },
          );
        },
      ),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final Product product;

  const _CategoryProductCard({required this.product});

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
                          tag: 'product_cat_${product.id}',
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
                      if (product.sellerName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Seller: ${product.sellerName}',
                          style: TextStyle(
                            color: AppColors.forestGreen.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                                  if (product.getNormalizedPriceString(product.getPriceForQuantity(1, state.currentMode == AppMode.b2b), product.variants.isNotEmpty ? product.variants.first.sizeName : null).isNotEmpty)
                                    Text(
                                      product.getNormalizedPriceString(product.getPriceForQuantity(1, state.currentMode == AppMode.b2b), product.variants.isNotEmpty ? product.variants.first.sizeName : null),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.lightText,
                                        fontWeight: FontWeight.w600,
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
