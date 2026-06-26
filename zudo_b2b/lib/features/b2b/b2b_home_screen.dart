import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';
import '../products/product_details_screen.dart';
import '../products/product_model.dart';
import '../shared_ui/wishlist_screen.dart';
import '../shared_ui/cart_screen.dart';
import '../shared_ui/history_screen.dart';
import '../shared_ui/profile_screen.dart';
import '../shared_ui/categories_screen.dart';
import '../feed/feed_screen.dart';

import '../shared_ui/auto_scroll_banner.dart';

class B2BHomeScreen extends StatefulWidget {
  const B2BHomeScreen({super.key});

  @override
  State<B2BHomeScreen> createState() => _B2BHomeScreenState();
}

class _B2BHomeScreenState extends State<B2BHomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  final _pincodeController = TextEditingController();

  final GlobalKey _bulkDealsKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlay;
  String _searchQuery = '';

  DateTime? _lastBackPressTime;
  late DateTime _appOpenTime;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pincodeController.dispose();
    _searchFocusNode.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  void _removeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  void _showSearchOverlay() {
    if (_searchOverlay != null) return;
    
    _searchOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardTheme.color ?? AppColors.white,
              child: Consumer<AppState>(
                builder: (context, state, child) {
                  final results = state.products.where((p) => 
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                  
                  if (results.isEmpty || _searchQuery.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final product = results[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text('₹${product.price}'),
                          onTap: () {
                            _searchFocusNode.unfocus();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_searchOverlay!);
  }

  @override
  void initState() {
    super.initState();
    _appOpenTime = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchQuery.isNotEmpty) {
        _showSearchOverlay();
      } else if (!_searchFocusNode.hasFocus) {
        _removeSearchOverlay();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchProducts();
      
      final state = context.read<AppState>();
      state.addListener(() {
        if (!state.hasShownPopup && state.popupAds.isNotEmpty && mounted) {
          final activeAds = state.popupAds.where((ad) => ad['isActive'] == true).toList();
          if (activeAds.isNotEmpty) {
            state.markPopupAsShown();
            _showPopupAd(activeAds.first);
          }
        }
      });
      // Check immediately if already loaded
      if (!state.hasShownPopup && state.popupAds.isNotEmpty) {
        final activeAds = state.popupAds.where((ad) => ad['isActive'] == true).toList();
        if (activeAds.isNotEmpty) {
          state.markPopupAsShown();
          _showPopupAd(activeAds.first);
        }
      }
    });
  }

  void _showPopupAd(Map<String, dynamic> ad) {
    if (!mounted) return;
    final imageUrl = ApiConstants.getFullImageUrl(ad['imageUrl']);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                    if (ad['title'] != null && ad['title'].toString().isNotEmpty)
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: Text(
                              ad['title'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      final appState = Provider.of<AppState>(context, listen: false);
      final email = appState.currentUser?.email ?? 'guest';
      final roleName = appState.currentMode == AppMode.b2b ? 'b2b' : 'b2c';
      final mockFcmToken = "mock-fcm-token-$roleName-$email";
      final activeToken = appState.activeFcmToken ?? mockFcmToken;
      
      final sessionDuration = DateTime.now().difference(_appOpenTime);
      print('B2B Session closed/paused after: ${sessionDuration.inSeconds}s');
      
      // 1. Low Session Time check (less than 30 seconds)
      if (sessionDuration < const Duration(seconds: 30)) {
        print('FCM: B2B low session detected. Triggering low_session FCM exit with token: $activeToken');
        ApiService.triggerExitNotification(activeToken, 'low_session');
      }
      
      // 2. Cart abandoned check
      if (appState.cart.isNotEmpty) {
        final firstProdName = appState.getFirstProductInCart();
        if (firstProdName != null) {
          print('FCM: B2B cart abandonment detected. First item: $firstProdName. Token: $activeToken');
          ApiService.triggerExitNotification(activeToken, 'cart_abandon', productName: firstProdName);
        }
      }
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppColors.forestGreen),
            SizedBox(width: 10),
            Text('Exit Zudo?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to exit the app? We will miss you!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // If not on Home tab (index 0), navigate back to Home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // On Home tab. Check consecutive presses (within 2 seconds)
        final now = DateTime.now();
        final isDoubleBack = _lastBackPressTime != null && 
            now.difference(_lastBackPressTime!) < const Duration(seconds: 2);
        
        if (isDoubleBack) {
          SystemNavigator.pop();
        } else {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit Zudo'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          final exitConfirmed = await _showExitDialog();
          if (exitConfirmed) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeView(),
            const CategoriesScreen(),
            const FeedScreen(),
            const CartScreen(),
            const HistoryScreen(),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeView() {
    return RefreshIndicator(
      edgeOffset: 0,
      onRefresh: () => context.read<AppState>().fetchProducts(),
      color: AppColors.forestGreen,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
              child: Consumer<AppState>(
                builder: (context, state, _) {
                  if (!state.isB2BVerified || state.isWaitingApproval) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verification Pending',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                Text(
                                  'Prices will be visible after your account is approved.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 24),
              child: _buildHeader(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    Consumer<AppState>(builder: (context, state, _) => _buildCategories(state)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBannerSection(),
                  const SizedBox(height: 32),
                  Consumer<AppState>(
                    builder: (context, state, child) {
                      if (state.newArrivals.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('New Arrivals'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.newArrivals.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 180,
                                  child: _ProductCard(product: state.newArrivals[index]),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),
                  Container(
                    key: _bulkDealsKey,
                    child: _buildSectionTitle('Bulk Deals'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
              return _buildProductGrid(state);
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final appState = context.watch<AppState>();
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: GestureDetector(
        onTap: _showLocationPicker,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warehouse Location',
                  style: TextStyle(color: AppColors.lightText, fontSize: 12),
                ),
                Text(
                  appState.currentCity ?? 'Select City',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(Icons.person_outline_rounded, color: Theme.of(context).colorScheme.tertiary),
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wholesale Hub,',
          style: TextStyle(color: AppColors.lightText, fontSize: 16),
        ),
        Text(
          'Bulk Savings!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return CompositedTransformTarget(
      link: _searchLayerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          focusNode: _searchFocusNode,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
            if (_searchOverlay != null) {
              _searchOverlay!.markNeedsBuild();
            } else if (val.isNotEmpty) {
              _showSearchOverlay();
            }
          },
          onTapOutside: (_) => _searchFocusNode.unfocus(),
          textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: false,
          hintText: 'Search wholesale inventory...',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.tertiary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    ),
  );
}

  Widget _buildCategories(AppState state) {
    final categories = ['All', ...state.categories.map((c) => c.name)];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final categoryName = categories[index];
          final isSelected = _selectedCategory == categoryName;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = categoryName;
              });
              if (_bulkDealsKey.currentContext != null) {
                Scrollable.ensureVisible(
                  _bulkDealsKey.currentContext!,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.tertiary : Theme.of(context).cardTheme.color ?? AppColors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.tertiary : AppColors.grey.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                categoryName,
                style: TextStyle(
                  color: isSelected ? AppColors.white : Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.darkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),
      ],
    );
  }

  Widget _buildProductGrid(AppState state) {
    final products = _selectedCategory == 'All' 
        ? state.products 
        : state.products.where((p) => p.category == _selectedCategory).toList();
        
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: Skeletonizer.sliver(
        enabled: state.isLoading && products.isEmpty,
        child: products.isEmpty && !state.isLoading
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No wholesale deals available'),
                  ),
                ),
              )
            : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    return _ProductCard(product: product);
                  },
                  childCount: products.length,
                ),
              ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(icon: Icons.home_rounded, isSelected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(icon: Icons.grid_view_rounded, isSelected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              _NavItem(icon: Icons.rss_feed_rounded, isSelected: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(icon: Icons.shopping_cart_outlined, isSelected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              _NavItem(icon: Icons.history_rounded, isSelected: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    final appState = context.watch<AppState>();
    final activeBanners = appState.banners.where((b) => b['isActive'] == true).toList();

    if (activeBanners.isNotEmpty) {
      return AutoScrollBanner(banners: activeBanners);
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.forestGreen, AppColors.leafGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Wholesale\nMarketplace',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Direct from farmers. Bulk pricing.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPicker() {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Warehouse City', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...appState.availableLocations.map((loc) => ListTile(
                title: Text(loc['city'] ?? ''),
                trailing: appState.currentCity == loc['city'] ? const Icon(Icons.check_circle, color: AppColors.forestGreen) : null,
                onTap: () {
                  appState.setTenant(loc['dbName']!, loc['city']!);
                  Navigator.pop(context);
                },
              )),
              const Divider(height: 32),
              const Text('Or Enter Pincode', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit pincode',
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () async {
                      final pc = _pincodeController.text.trim();
                      if (pc.length != 6) return;
                      
                      Navigator.pop(context);
                      final served = await appState.fetchTenantByPincode(pc);
                      if (!served && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delivery not available at this pincode.'))
                        );
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final inWishlist = state.isInWishlist(product.id);
        
        return Container(
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
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Hero(
                          tag: 'product_b2b_${product.id}',
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
                                if (!state.isB2BVerified || state.isWaitingApproval)
                                  Text(
                                    'Price shown post verification',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.orange.shade800,
                                    ),
                                  )
                                else
                                  Text(
                                    '₹${product.b2bPrice}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                  ),
                                Text(
                                  'Min. Bill: \u20b92,000',
                                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (state.isB2BVerified && !state.isWaitingApproval)
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
                                        content: Text('${product.name} added to wholesale cart'),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.tertiary : AppColors.lightText,
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 135.0;

  @override
  double get maxExtent => 135.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return true;
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
