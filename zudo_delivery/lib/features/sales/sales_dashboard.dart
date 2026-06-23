import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';

double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

int parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}


class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = context.read<AppState>();
      state.fetchSalesCustomers();
      state.fetchSalesCatalog();
    });
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch dialer';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot make phone call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final stores = appState.salesCustomers;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Sales Partner Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out from the Sales panel?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[800]),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        appState.logout();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Sales Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.indigo[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Sales Executive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'sales@zudo.co.in',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Assigned Pincodes:',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          stores.isNotEmpty
                              ? stores.map((s) => s['pincode'].toString()).toSet().join(', ')
                              : 'Loading assigned coverage...',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),

          // Title & Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'B2B Customer Directory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Text(
                    '${stores.length} Retailers',
                    style: TextStyle(color: Colors.indigo[800], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: appState.isLoading && stores.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : RefreshIndicator(
                    edgeOffset: 0,
                    onRefresh: () => appState.fetchSalesCustomers(),
                    child: stores.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.storefront_rounded, size: 80, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No verified B2B retailers found\nin your assigned pincodes.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: stores.length,
                            itemBuilder: (context, index) {
                              final store = stores[index];
                              return _buildStoreCard(store);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.store_rounded, color: Colors.indigo[800], size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['businessName'] ?? store['name'] ?? 'Retail Shop',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${store['name'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store['address'] ?? 'No address provided',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pin_drop_outlined, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pincode: ${store['pincode'] ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo[800],
                      side: BorderSide(color: Colors.indigo.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 20),
                    label: const Text('Call Store', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _makeCall(store['phone'] ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: const Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SalesOrderDesk(customer: store),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Sales Order Desk full catalog selection panel
class SalesOrderDesk extends StatefulWidget {
  final Map<String, dynamic> customer;
  const SalesOrderDesk({super.key, required this.customer});

  @override
  State<SalesOrderDesk> createState() => _SalesOrderDeskState();
}

class _SalesOrderDeskState extends State<SalesOrderDesk> {
  final Map<String, int> _cart = {}; // productId -> quantity
  String _searchQuery = '';
  String? _activeCategoryId;
  String? _activeCategoryName;
  String? _activeSubCategoryId;
  String? _activeSubCategoryName;

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalesCartSheet(
        cart: _cart,
        catalog: context.read<AppState>().salesCatalog,
        customer: widget.customer,
        onQuantityChanged: (productId, newQty) {
          setState(() {
            if (newQty <= 0) {
              _cart.remove(productId);
            } else {
              _cart[productId] = newQty;
            }
          });
        },
        onClearCart: () {
          setState(() {
            _cart.clear();
          });
        },
        onCheckoutPressed: () {
          final itemsPayload = _cart.entries.map((e) {
            final parts = e.key.split('_');
            final actualId = parts[0];
            final variant = parts.length > 1 ? parts[1] : null;
            return {
              'product': actualId,
              'quantity': e.value,
              if (variant != null) 'sizeName': variant,
            };
          }).toList();

          double cartTotal = 0.0;
          _cart.forEach((pId, qty) {
            final parts = pId.split('_');
            final actualId = parts[0];
            final variant = parts.length > 1 ? parts[1] : null;
            final product = context.read<AppState>().salesCatalog.firstWhere((p) => p['_id'] == actualId, orElse: () => null);
            if (product != null) {
              cartTotal += _getProductB2BPrice(product, qty, variant) * qty;
            }
          });

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            builder: (context) => SalesCheckoutPanel(
              customerId: widget.customer['_id'],
              items: itemsPayload,
              totalAmount: cartTotal,
              customerData: widget.customer,
              onSuccess: () {
                setState(() {
                  _cart.clear();
                });
              },
            ),
          );
        },
      ),
    );
  }

  double _getProductB2BPrice(Map<String, dynamic> p, int qty, [String? variantName]) {
    final variants = (p['variants'] as List?) ?? (p['b2b'] as List?) ?? (p['b2c'] as List?);
    var tiers = p['priceTiers'];
    var basePrice = (p['b2bPrice'] ?? p['price'] ?? 0).toDouble();

    if (variantName != null && variants != null && variants.isNotEmpty) {
      final variant = variants.firstWhere(
        (v) => (v['sizeName']?.toString() ?? v['packetSize']?.toString() ?? v['size']?.toString() ?? v['name']?.toString() ?? '') == variantName,
        orElse: () => variants.first,
      );
      if (variant != null) {
        basePrice = (variant['b2bPrice'] ?? variant['price'] ?? basePrice).toDouble();
        tiers = variant['priceTiers'] ?? tiers;
      }
    }

    if (tiers != null && tiers is List) {
      final List tList = tiers;
      for (var t in tList) {
        if (qty >= (t['minQty'] ?? 0)) {
          basePrice = (t['price'] ?? basePrice).toDouble();
        }
      }
    }
    return basePrice;
  }

  int _getMOQ(Map<String, dynamic> p) {
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final catalog = appState.salesCatalog;
    final categories = appState.salesCategories;

    final filteredCatalog = catalog.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      
      // Category filter
      bool matchesCategory = false;
      if (_activeCategoryId == null) {
        matchesCategory = true;
      } else if (p['categoryId'] != null) {
        final catVal = p['categoryId'];
        if (catVal is Map) {
          matchesCategory = (catVal['_id']?.toString() == _activeCategoryId);
        } else {
          matchesCategory = (catVal.toString() == _activeCategoryId);
        }
      } else if (p['category'] != null) {
        final catVal = p['category'];
        if (catVal is Map) {
          matchesCategory = (catVal['_id']?.toString() == _activeCategoryId);
        } else {
          matchesCategory = (catVal.toString() == _activeCategoryId);
        }
      }

      // Sub-category filter
      bool matchesSubCategory = false;
      if (_activeSubCategoryId == null || _activeSubCategoryId == 'ALL') {
        matchesSubCategory = true;
      } else if (p['subCategoryId'] != null) {
        final subVal = p['subCategoryId'];
        if (subVal is Map) {
          matchesSubCategory = (subVal['_id']?.toString() == _activeSubCategoryId);
        } else {
          matchesSubCategory = (subVal.toString() == _activeSubCategoryId);
        }
      } else if (p['subCategory'] != null) {
        final subVal = p['subCategory'];
        if (subVal is Map) {
          matchesSubCategory = (subVal['_id']?.toString() == _activeSubCategoryId);
        } else {
          matchesSubCategory = (subVal.toString() == _activeSubCategoryId);
        }
      }

      return matchesSearch && matchesCategory && matchesSubCategory;
    }).toList();

    int totalItems = 0;
    double cartTotal = 0.0;
    _cart.forEach((pId, qty) {
      final product = catalog.firstWhere((p) => p['_id'] == pId, orElse: () => null);
      if (product != null) {
        totalItems += qty;
        cartTotal += _getProductB2BPrice(product, qty) * qty;
      }
    });

    // Resolve subcategories for the selected category
    final activeCat = _activeCategoryId == null
        ? null
        : categories.firstWhere((c) => c['_id'].toString() == _activeCategoryId, orElse: () => null);
    final List subCategories = activeCat != null && activeCat['subCategories'] != null
        ? activeCat['subCategories']
        : [];

    return PopScope(
      canPop: _activeCategoryId == null && _activeSubCategoryId == null && _searchQuery.isEmpty,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_searchQuery.isNotEmpty) {
          setState(() {
            _searchQuery = '';
          });
        } else if (_activeSubCategoryId != null) {
          setState(() {
            _activeSubCategoryId = null;
            _activeSubCategoryName = null;
          });
        } else if (_activeCategoryId != null) {
          setState(() {
            _activeCategoryId = null;
            _activeCategoryName = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Place Order On Behalf', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                widget.customer['businessName'] ?? widget.customer['name'] ?? 'B2B Customer',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.indigo[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                setState(() {
                  _searchQuery = '';
                });
              } else if (_activeSubCategoryId != null) {
                setState(() {
                  _activeSubCategoryId = null;
                  _activeSubCategoryName = null;
                });
              } else if (_activeCategoryId != null) {
                setState(() {
                  _activeCategoryId = null;
                  _activeCategoryName = null;
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                  onPressed: _openCartSheet,
                ),
                if (totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            // Catalog Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.indigo[800],
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _activeCategoryId == null
                      ? 'Search products globally...'
                      : 'Search inside $_activeCategoryName...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // Breadcrumbs Bar (only if inside category)
            _buildBreadcrumbs(),

            const Divider(height: 1, thickness: 1),

            // Dynamic Body Content based on Navigation state
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildProductsView(filteredCatalog)
                  : _activeCategoryId == null
                      ? _buildCategoriesGrid(categories)
                      : (subCategories.isNotEmpty && _activeSubCategoryId == null)
                          ? _buildSubCategoriesGrid(subCategories)
                          : _buildProductsView(filteredCatalog),
            ),
          ],
        ),
        bottomSheet: totalItems == 0
            ? null
            : Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.indigo[800],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: InkWell(
                    onTap: _openCartSheet,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$totalItems Items Added',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${cartTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo[800],
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                            label: const Text('View Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _openCartSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Breadcrumbs for easy navigation
  Widget _buildBreadcrumbs() {
    if (_activeCategoryId == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (_activeSubCategoryId != null) {
                  _activeSubCategoryId = null;
                  _activeSubCategoryName = null;
                } else {
                  _activeCategoryId = null;
                  _activeCategoryName = null;
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Colors.indigo[800]),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 16, width: 1, color: Colors.grey.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.home_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  _activeCategoryName ?? 'Category',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                ),
                if (_activeSubCategoryName != null) ...[
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
                  Expanded(
                    child: Text(
                      _activeSubCategoryName == 'ALL' ? 'All Products' : _activeSubCategoryName!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[800], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Categories Grid View (Exactly copied styling from b2b categories screen)
  Widget _buildCategoriesGrid(List<dynamic> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No categories available', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final catId = category['_id']?.toString();
        final catName = category['name'] ?? 'Category';
        final imageUrl = category['imageUrl'] ?? '';

        return GestureDetector(
          onTap: () {
            setState(() {
              _activeCategoryId = catId;
              _activeCategoryName = catName;
              _activeSubCategoryId = null;
              _activeSubCategoryName = null;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.category_outlined, size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.category_outlined, size: 40, color: Colors.grey),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.75), Colors.transparent],
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
                      catName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Sub-Categories Grid View
  Widget _buildSubCategoriesGrid(List<dynamic> subCategories) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: subCategories.length + 1, // Include custom "All Products" card
      itemBuilder: (context, index) {
        final isAllCard = index == 0;
        
        if (isAllCard) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeSubCategoryId = 'ALL';
                _activeSubCategoryName = 'ALL';
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.shade100, width: 2),
                color: Colors.indigo.shade50.withOpacity(0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view_rounded, size: 48, color: Colors.indigo[800]),
                  const SizedBox(height: 12),
                  Text(
                    'All Products',
                    style: TextStyle(
                      color: Colors.indigo[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse entire category',
                    style: TextStyle(color: Colors.indigo.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }

        final subCat = subCategories[index - 1];
        final subId = subCat['_id']?.toString();
        final subName = subCat['name'] ?? 'Subcategory';
        final imageUrl = subCat['imageUrl'] ?? '';

        return GestureDetector(
          onTap: () {
            setState(() {
              _activeSubCategoryId = subId;
              _activeSubCategoryName = subName;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.subdirectory_arrow_right, size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.subdirectory_arrow_right, size: 40, color: Colors.grey),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.75), Colors.transparent],
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
                      subName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsView(List<dynamic> filteredCatalog) {
    if (filteredCatalog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products found matching "$_searchQuery"'
                  : 'No products in this category.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: filteredCatalog.length,
      itemBuilder: (context, index) {
        final product = filteredCatalog[index];
        final pId = product['_id'];
        final qty = _cart[pId] ?? 0;
        final b2bPrice = _getProductB2BPrice(product, qty > 0 ? qty : 1);
        final moq = _getMOQ(product);

        // Resolve seller name
        final sellerName = product['sellerName'] ?? 'Zudo Official';
        
        // Resolve subcategory name
        String subCatName = '';
        if (product['subCategoryId'] != null) {
          subCatName = product['subCategoryId'] is Map ? (product['subCategoryId']['name'] ?? '') : '';
        } else if (product['subCategory'] != null) {
          subCatName = product['subCategory'] is Map ? (product['subCategory']['name'] ?? '') : product['subCategory'].toString();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalesProductDetailsScreen(
                  product: product,
                  initialQty: qty,
                  moq: moq,
                  b2bPrice: b2bPrice,
                  onQuantityChanged: (newQty, variantName) {
                    setState(() {
                      final cartKey = variantName != null ? '${pId}_$variantName' : pId;
                      if (newQty == 0) {
                        _cart.remove(cartKey);
                      } else {
                        _cart[cartKey] = newQty;
                      }
                    });
                  },
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image cover
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        product['imageUrl'] ?? product['image'] ?? 'https://lightgreen-trout-176417.hostingersite.com/uploads/default-product.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image, color: Colors.grey, size: 36),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.15), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Info body
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product Name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seller: $sellerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subCatName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subCatName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹$b2bPrice',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Colors.indigo[800],
                                ),
                              ),
                              Text(
                                'Min. Bill: ₹2,000',
                                style: TextStyle(fontSize: 9, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        
                        // Cart / Quantity selector button
                        qty == 0
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _cart[pId] = 1;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              )
                            : Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (qty <= 1) {
                                            _cart.remove(pId);
                                          } else {
                                            _cart[pId] = qty - 1;
                                          }
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.remove, size: 14, color: Colors.black54),
                                      ),
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _cart[pId] = qty + 1;
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.add, size: 14, color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
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

class SalesCartSheet extends StatefulWidget {
  final Map<String, int> cart;
  final List<dynamic> catalog;
  final Map<String, dynamic> customer;
  final Function(String, int) onQuantityChanged;
  final Function() onClearCart;
  final Function() onCheckoutPressed;

  const SalesCartSheet({
    super.key,
    required this.cart,
    required this.catalog,
    required this.customer,
    required this.onQuantityChanged,
    required this.onClearCart,
    required this.onCheckoutPressed,
  });

  @override
  State<SalesCartSheet> createState() => _SalesCartSheetState();
}

class _SalesCartSheetState extends State<SalesCartSheet> {
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double _getProductB2BPrice(Map<String, dynamic> p, int qty, [String? variantName]) {
    final variants = (p['variants'] as List?) ?? (p['b2b'] as List?) ?? (p['b2c'] as List?);
    var tiers = p['priceTiers'];
    var basePrice = parseDouble(p['b2bPrice'] ?? p['price'] ?? 0);

    if (variantName != null && variants != null && variants.isNotEmpty) {
      final variant = variants.firstWhere(
        (v) => (v['sizeName']?.toString() ?? v['packetSize']?.toString() ?? v['size']?.toString() ?? v['name']?.toString() ?? '') == variantName,
        orElse: () => variants.first,
      );
      if (variant != null) {
        basePrice = parseDouble(variant['b2bPrice'] ?? variant['price'] ?? basePrice);
        tiers = variant['priceTiers'] ?? tiers;
      }
    }

    if (tiers != null && tiers is List) {
      final List tList = tiers;
      for (var t in tList) {
        if (qty >= (parseInt(t['minQty'] ?? 0))) {
          basePrice = parseDouble(t['price'] ?? basePrice);
        }
      }
    }
    return basePrice;
  }

  int _getMOQ(Map<String, dynamic> p) {
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> itemsInCart = {};
    widget.cart.forEach((cartKey, qty) {
      final parts = cartKey.split('_');
      final pId = parts[0];
      final variantName = parts.length > 1 ? parts[1] : null;

      final product = widget.catalog.firstWhere((p) => p['_id'] == pId, orElse: () => null);
      if (product != null) {
        itemsInCart[cartKey] = {
          'product': product,
          'qty': qty,
          'variantName': variantName,
        };
      }
    });

    double subtotal = 0.0;
    double originalTotal = 0.0; // before tier discounts
    itemsInCart.forEach((cartKey, data) {
      final product = data['product'];
      final qty = data['qty'];
      final variantName = data['variantName'];
      
      final basePrice = _getProductB2BPrice(product, 1, variantName);
      final activePrice = _getProductB2BPrice(product, qty, variantName);
      
      subtotal += activePrice * qty;
      originalTotal += basePrice * qty;
    });

    double totalSavings = originalTotal - subtotal;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            // Slide indicator
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Desk Cart',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Client: ${widget.customer['businessName'] ?? widget.customer['name'] ?? 'B2B Client'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (itemsInCart.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red[800]),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      label: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Cart'),
                            content: const Text('Are you sure you want to remove all items from the cart?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                                onPressed: () => Navigator.pop(context),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                                child: const Text('Clear', style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onClearCart();
                                  Navigator.pop(context); // close cart sheet
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Cart Items List
            Expanded(
              child: itemsInCart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.shopping_basket_rounded, size: 64, color: Colors.indigo[800]),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search or browse B2B products and\nadd them here to place an order.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo[800],
                              side: BorderSide(color: Colors.indigo.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Browse Products', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: itemsInCart.length,
                      itemBuilder: (context, index) {
                        final cartKey = itemsInCart.keys.elementAt(index);
                        final itemData = itemsInCart[cartKey];
                        final product = itemData['product'];
                        final qty = itemData['qty'];
                        final variantName = itemData['variantName'];
                        final moq = _getMOQ(product);
                        final basePrice = _getProductB2BPrice(product, 1, variantName);
                        final activePrice = _getProductB2BPrice(product, qty, variantName);
                        final sellerName = product['sellerName'] ?? 'Zudo Official';

                        // Check bulk tiers status
                        final tiers = product['priceTiers'] as List?;
                        Widget tierStatusBadge = const SizedBox.shrink();
                        if (tiers != null && tiers.isNotEmpty) {
                          // Sort ascending to find tiers
                          final sortedTiers = List.from(tiers)..sort((a, b) => parseInt(a['minQty']).compareTo(parseInt(b['minQty'])));
                          
                          int? nextTierQty;
                          double? nextTierPrice;
                          int? activeTierQty;
                          
                          for (var tier in sortedTiers) {
                            final minQty = parseInt(tier['minQty']);
                            if (qty >= minQty) {
                              activeTierQty = minQty;
                            } else if (nextTierQty == null) {
                              nextTierQty = minQty;
                              nextTierPrice = parseDouble(tier['price']);
                            }
                          }

                          if (activeTierQty != null && nextTierQty != null) {
                            final diff = nextTierQty - qty;
                            tierStatusBadge = Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded, size: 12, color: Colors.amber.shade900),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add $diff more to get units at ₹${nextTierPrice!.toStringAsFixed(2)}!',
                                    style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          } else if (activeTierQty != null && nextTierQty == null) {
                            tierStatusBadge = Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Max bulk tier discount unlocked!',
                                    style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          } else if (activeTierQty == null && nextTierQty != null) {
                            final diff = nextTierQty - qty;
                            tierStatusBadge = Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.indigo.shade100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 12, color: Colors.indigo[800]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add $diff more to unlock bulk price of ₹${nextTierPrice!.toStringAsFixed(2)}!',
                                    style: TextStyle(fontSize: 10, color: Colors.indigo[800], fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          color: Colors.grey[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product['imageUrl'] ?? product['image'] ?? 'https://lightgreen-trout-176417.hostingersite.com/uploads/default-product.png',
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      width: 72,
                                      height: 72,
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] ?? 'Product Name',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      if (variantName != null && variantName.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Size: $variantName', style: TextStyle(fontSize: 10, color: Colors.grey.shade800)),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        'Sold by: $sellerName',
                                        style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${activePrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.indigo[800],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (activePrice < basePrice)
                                            Text(
                                              '₹${basePrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          const Spacer(),
                                          Text(
                                            'Subtotal: ₹${(activePrice * qty).toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                      
                                      tierStatusBadge,

                                      const SizedBox(height: 8),

                                      // Quantity Adjuster & Delete
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Min. Bill: ₹2,000',
                                            style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: [
                                              // Minus button
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: const Icon(Icons.remove, size: 14, color: Colors.black87),
                                                ),
                                                onPressed: () {
                                                  if (qty <= 1) {
                                                    // Remove
                                                    widget.onQuantityChanged(cartKey, 0);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Removed ${product['name']} from cart'),
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  } else {
                                                    widget.onQuantityChanged(cartKey, qty - 1);
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '$qty',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(width: 10),
                                              // Plus button
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: const Icon(Icons.add, size: 14, color: Colors.black87),
                                                ),
                                                onPressed: () {
                                                  widget.onQuantityChanged(cartKey, qty + 1);
                                                },
                                              ),
                                              const SizedBox(width: 16),
                                              // Quick Delete Bin Icon
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(Icons.delete_outline_rounded, color: Colors.red[800], size: 20),
                                                onPressed: () {
                                                  widget.onQuantityChanged(cartKey, 0);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Removed ${product['name']} from cart'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
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
                    ),
            ),

            // Summary Section & Checkout Button
            if (itemsInCart.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Savings alert
                      if (totalSavings > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.stars_rounded, color: Colors.green[800], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Wholesale Tier Savings: ₹${totalSavings.toStringAsFixed(2)}!',
                                style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          Text(
                            '₹${subtotal.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.indigo[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Minimum bill warning
                      if (subtotal < 2000)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Min. bill ₹2,000 required. Add ₹${(2000 - subtotal).toStringAsFixed(2)} more.',
                                  style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: Opacity(
                          opacity: subtotal < 2000 ? 0.5 : 1.0,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                            label: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            onPressed: subtotal < 2000 ? null : () {
                              Navigator.pop(context); // Close cart drawer
                              widget.onCheckoutPressed(); // Proceed
                            },
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
}

// Checkout Modal Panel for verifying slot and placing orders
class SalesCheckoutPanel extends StatefulWidget {
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final Map<String, dynamic> customerData;
  final VoidCallback onSuccess;

  const SalesCheckoutPanel({
    super.key,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.customerData,
    required this.onSuccess,
  });

  @override
  State<SalesCheckoutPanel> createState() => _SalesCheckoutPanelState();
}

class _SalesCheckoutPanelState extends State<SalesCheckoutPanel> {
  String _paymentMethod = 'COD';
  bool _isPlacing = false;
  Map<String, dynamic>? _selectedAddress;
  List<dynamic> _availableAddresses = [];

  String? _selectedSlot;

  bool _isTimeBefore(String orderedBefore) {
    final now = DateTime.now();
    final parts = orderedBefore.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final int min = int.parse(timeParts[1]);
    if (parts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
    
    final targetTime = DateTime(now.year, now.month, now.day, hour, min);
    return now.isBefore(targetTime);
  }

  List<Map<String, dynamic>> _getAvailableSlots(List<Map<String, dynamic>> dbSlots) {
    List<Map<String, dynamic>> available = [];
    
    String globalCutoff = '';
    for (var slot in dbSlots) {
      if (slot.containsKey('SameDayCutoff') && slot['SameDayCutoff'] != null) {
        globalCutoff = slot['SameDayCutoff'].toString();
      }
    }
    
    for (var slot in dbSlots) {
      if (!slot.containsKey('startTime') || slot['startTime'] == null) continue;
      if (!slot.containsKey('endTime') || slot['endTime'] == null) continue;
      
      final timeStr = '${slot['startTime']} - ${slot['endTime']}';
      final orderedBefore = (slot['orderedBeforeTime'] != null && slot['orderedBeforeTime'].toString().isNotEmpty) 
          ? slot['orderedBeforeTime'].toString() 
          : globalCutoff;
      
      final isSameDay = slot['isSameDay'] == true;
      bool isDisabled = false;
      if (isSameDay && orderedBefore.isNotEmpty) {
        final isBefore = _isTimeBefore(orderedBefore);
        if (!isBefore) {
          isDisabled = true;
        }
      }
      
      available.add({
        'time': timeStr, 
        'label': isSameDay ? 'Same Day' : timeStr,
        'isSameDay': isSameDay,
        'isDisabled': isDisabled,
        'cutoff': orderedBefore,
      });
    }
    
    return available;
  }

  @override
  void initState() {
    super.initState();
    _initAddresses();
  }

  void _initAddresses() {
    final rawAddresses = widget.customerData['savedAddresses'];
    if (rawAddresses != null && rawAddresses is List && rawAddresses.isNotEmpty) {
      _availableAddresses = List.from(rawAddresses);
      final defaultAddr = _availableAddresses.firstWhere(
        (addr) => addr['isDefault'] == true,
        orElse: () => _availableAddresses.first,
      );
      _selectedAddress = Map<String, dynamic>.from(defaultAddr);
    } else {
      _selectedAddress = {
        'name': widget.customerData['name'] ?? 'B2B Customer',
        'phone': widget.customerData['phone'] ?? 'N/A',
        'address': widget.customerData['address'] ?? 'No Address',
        'city': widget.customerData['city'] ?? 'Bengaluru',
        'pincode': widget.customerData['pincode'] ?? 'N/A',
        'state': widget.customerData['state'] ?? 'Karnataka',
        'lat': (widget.customerData['lat'] ?? 12.9716).toDouble(),
        'lng': (widget.customerData['lng'] ?? 77.5946).toDouble(),
      };
      _availableAddresses = [_selectedAddress];
    }
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _availableAddresses.length,
                itemBuilder: (context, index) {
                  final addr = _availableAddresses[index];
                  final isSelected = _selectedAddress?['address'] == addr['address'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo.shade50.withOpacity(0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.indigo.shade300 : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(
                        Icons.location_on_rounded,
                        color: isSelected ? Colors.indigo[800] : Colors.grey[400],
                        size: 24,
                      ),
                      title: Text(
                        addr['name'] ?? 'Address ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.indigo[800] : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            addr['address'] ?? '',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                          Text(
                            '${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['pincode'] ?? ''}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: Colors.indigo[800])
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedAddress = Map<String, dynamic>.from(addr);
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final appState = context.read<AppState>();

    try {
      final shippingAddress = {
        'name': _selectedAddress?['name'] ?? widget.customerData['name'] ?? 'B2B Customer',
        'phone': _selectedAddress?['phone'] ?? widget.customerData['phone'] ?? 'N/A',
        'address': _selectedAddress?['address'] ?? widget.customerData['address'] ?? 'No Address',
        'city': _selectedAddress?['city'] ?? appState.currentCity ?? 'Bengaluru',
        'pincode': _selectedAddress?['pincode'] ?? widget.customerData['pincode'] ?? 'N/A',
        'state': _selectedAddress?['state'] ?? 'Karnataka',
        'lat': (_selectedAddress?['lat'] ?? 12.9716).toDouble(),
        'lng': (_selectedAddress?['lng'] ?? 77.5946).toDouble(),
      };

      await appState.placeSalesOrderOnBehalf(
        customerId: widget.customerId,
        items: widget.items,
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
        deliverySlot: _selectedSlot!,
      );

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.pop(context); // close catalog page
        
        // Show stunning success dialog!
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 72),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order has been successfully registered on behalf of ${widget.customerData['businessName'] ?? widget.customerData['name']}. It is now visible in their history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Confirm Order Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),

          // Business Details
          const Text('Customer Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            widget.customerData['businessName'] ?? widget.customerData['name'] ?? 'B2B Customer',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Address Selection Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              if (_availableAddresses.length > 1)
                GestureDetector(
                  onTap: _showAddressPicker,
                  child: Text(
                    'Change Address',
                    style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.forestGreen),
                    const SizedBox(width: 8),
                    Text(
                      _selectedAddress?['name'] ?? 'Primary Address',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedAddress?['address'] ?? 'No Address Provided',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedAddress?['city'] ?? ''}, ${_selectedAddress?['state'] ?? ''} - ${_selectedAddress?['pincode'] ?? ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (_selectedAddress?['phone'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${_selectedAddress?['phone']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('Delivery Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final dbSlots = context.watch<AppState>().deliverySlots;
              if (dbSlots.isEmpty) return const Center(child: CircularProgressIndicator());
              
              final availableSlots = _getAvailableSlots(dbSlots);
              if (_selectedSlot == null || !availableSlots.any((s) => s['time'] == _selectedSlot && s['isDisabled'] != true)) {
                final firstEnabled = availableSlots.firstWhere((s) => s['isDisabled'] != true, orElse: () => availableSlots.first);
                _selectedSlot = firstEnabled['time'];
              }
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableSlots.map((slotData) {
                    final slot = slotData['time'] as String;
                    final isSelected = _selectedSlot == slot;
                    final isSameDay = slotData['isSameDay'] as bool;
                    final isDisabled = slotData['isDisabled'] == true;
                    final cutoff = slotData['cutoff'] as String;
                    
                    return GestureDetector(
                      onTap: () {
                        if (isDisabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order before $cutoff for same day delivery'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          setState(() => _selectedSlot = slot);
                        }
                      },
                      child: Opacity(
                        opacity: isDisabled ? 0.5 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.indigo.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.indigo : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                            child: Text(
                              slotData['label'],
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.indigo 
                                    : (isDisabled ? Colors.grey : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
          ),
          const SizedBox(height: 20),

          // Payment Methods
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('COD', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _paymentMethod == 'COD',
                  selectedColor: Colors.indigo.shade50,
                  checkmarkColor: Colors.indigo[800],
                  labelStyle: TextStyle(color: _paymentMethod == 'COD' ? Colors.indigo[800] : Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _paymentMethod == 'COD' ? Colors.indigo.shade200 : Colors.grey.shade300),
                  ),
                  onSelected: (val) => setState(() => _paymentMethod = 'COD'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('UPI', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _paymentMethod == 'UPI at Delivery',
                  selectedColor: Colors.indigo.shade50,
                  checkmarkColor: Colors.indigo[800],
                  labelStyle: TextStyle(color: _paymentMethod == 'UPI at Delivery' ? Colors.indigo[800] : Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _paymentMethod == 'UPI at Delivery' ? Colors.indigo.shade200 : Colors.grey.shade300),
                  ),
                  onSelected: (val) => setState(() => _paymentMethod = 'UPI at Delivery'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Cash', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _paymentMethod == 'Cash at Delivery',
                  selectedColor: Colors.indigo.shade50,
                  checkmarkColor: Colors.indigo[800],
                  labelStyle: TextStyle(color: _paymentMethod == 'Cash at Delivery' ? Colors.indigo[800] : Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _paymentMethod == 'Cash at Delivery' ? Colors.indigo.shade200 : Colors.grey.shade300),
                  ),
                  onSelected: (val) => setState(() => _paymentMethod = 'Cash at Delivery'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.forestGreen),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Confirm Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _isPlacing ? null : _placeOrder,
              child: _isPlacing
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm & Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// Sleek B2B product details screen with tier pricing tables and order desk sync
class SalesProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int initialQty;
  final int moq;
  final double b2bPrice;
  final void Function(int, String?) onQuantityChanged;

  const SalesProductDetailsScreen({
    super.key,
    required this.product,
    required this.initialQty,
    required this.moq,
    required this.b2bPrice,
    required this.onQuantityChanged,
  });

  @override
  State<SalesProductDetailsScreen> createState() => _SalesProductDetailsScreenState();
}

class _SalesProductDetailsScreenState extends State<SalesProductDetailsScreen> {
  late int _qty;
  String? selectedVariant;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty;
    final variants = (widget.product['variants'] as List?) ?? (widget.product['b2b'] as List?) ?? (widget.product['b2c'] as List?);
    if (variants != null && variants.isNotEmpty) {
      selectedVariant = variants[0]['sizeName']?.toString() ?? variants[0]['packetSize']?.toString() ?? variants[0]['size']?.toString() ?? variants[0]['name']?.toString() ?? '';
    }
  }

  double _getProductB2BPrice(Map<String, dynamic> p, int quantity, String? variantName) {
    final variants = (p['variants'] as List?) ?? (p['b2b'] as List?) ?? (p['b2c'] as List?);
    var tiers = p['priceTiers'];
    var basePrice = (p['b2bPrice'] ?? p['price'] ?? 0.0) as num;

    if (variantName != null && variants != null && variants.isNotEmpty) {
      final variant = variants.firstWhere(
        (v) => (v['sizeName']?.toString() ?? v['packetSize']?.toString() ?? v['size']?.toString() ?? v['name']?.toString() ?? '') == variantName,
        orElse: () => variants.first,
      );
      if (variant != null) {
        basePrice = (variant['b2bPrice'] ?? variant['price'] ?? basePrice) as num;
        tiers = variant['priceTiers'] ?? tiers;
      }
    }

    if (tiers == null || tiers is! List || tiers.isEmpty) {
      return basePrice.toDouble();
    }
    double activePrice = basePrice.toDouble();
    for (var tier in tiers) {
      final minQty = (tier['minQty'] ?? 0) as num;
      final price = (tier['price'] ?? 0.0) as num;
      if (quantity >= minQty) {
        activePrice = price.toDouble();
      }
    }
    return activePrice;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final sellerName = product['sellerName'] ?? 'Zudo Official';
    final currentB2BPrice = _getProductB2BPrice(product, _qty > 0 ? _qty : 1, selectedVariant);
    
    String subCatName = '';
    if (product['subCategoryId'] != null) {
      subCatName = product['subCategoryId'] is Map ? (product['subCategoryId']['name'] ?? '') : '';
    } else if (product['subCategory'] != null) {
      subCatName = product['subCategory'] is Map ? (product['subCategory']['name'] ?? '') : product['subCategory'].toString();
    }

    final tiers = product['priceTiers'] as List?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Slivers AppBar for Cover Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.indigo[800],
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_detail_${product['_id']}',
                child: Image.network(
                  product['imageUrl'] ?? product['image'] ?? 'https://lightgreen-trout-176417.hostingersite.com/uploads/default-product.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image, color: Colors.grey, size: 80),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pricing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product['price'] != null && product['price'] != currentB2BPrice) ...[
                            Text(
                              '₹${product['price']}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            '₹$currentB2BPrice',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              color: Colors.indigo[800],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              (product['rating'] ?? 5.0).toString(),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product Title & Seller
                  Text(
                    product['name'] ?? 'Product Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sold by: $sellerName',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subCatName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Category: $subCatName',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                  
                  const SizedBox(height: 24),

                  Builder(
                    builder: (context) {
                      final variants = (widget.product['variants'] as List?) ?? (widget.product['b2b'] as List?) ?? (widget.product['b2c'] as List?);
                      if (variants != null && variants.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: variants.map((v) {
                                final sName = v['sizeName']?.toString() ?? v['packetSize']?.toString() ?? v['size']?.toString() ?? v['name']?.toString() ?? '';
                                final isSelected = selectedVariant == sName;
                                return ChoiceChip(
                                  label: Text(sName.isNotEmpty ? sName : 'Standard'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedVariant = sName;
                                      });
                                    }
                                  },
                                  selectedColor: Colors.indigo.shade100,
                                  backgroundColor: Colors.grey.shade100,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // MOQ Wholesale Requirement Badge
                  if (widget.moq > 1) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.indigo[800]),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wholesale Requirement',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[800]),
                              ),
                              Text(
                                'Minimum order: ${widget.moq} ${product['unit'] ?? 'pcs'}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pricing Tiers Table
                  if (tiers != null && tiers.isNotEmpty) ...[
                    const Text(
                      'Bulk Pricing Tiers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Quantity', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                Text('Price per Unit', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...tiers.map((tier) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${tier['minQty']}+ ${product['unit'] ?? 'pcs'}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${tier['price']}',
                                    style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text(
                    'Product Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['description'] ?? 'Our premium quality products are sourced directly from sustainable farms. We ensure the highest standards of hygiene and quality control from farm to your kitchen.',
                    style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_qty > 0) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: Colors.indigo),
                      onPressed: () {
                        setState(() {
                          if (_qty <= widget.moq) {
                            _qty = 0;
                          } else {
                            _qty--;
                          }
                          widget.onQuantityChanged(_qty, selectedVariant);
                        });
                      },
                    ),
                    Text(
                      '$_qty',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.indigo),
                      onPressed: () {
                        setState(() {
                          _qty++;
                          widget.onQuantityChanged(_qty, selectedVariant);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_qty == 0) {
                      _qty = widget.moq;
                    } else {
                      _qty += widget.moq;
                    }
                    widget.onQuantityChanged(_qty, selectedVariant);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product['name']} quantity updated to $_qty'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_qty > 0 ? 'Add More' : 'Add to Order Desk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
