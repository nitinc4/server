import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../orders/order_model.dart';
import 'order_details_screen.dart';
import 'deposit_screen.dart';
import 'attendance_screen.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppColors.forestGreen),
            SizedBox(width: 10),
            Text('Exit Zudo Delivery?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to exit the delivery partner app?'),
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

  void _showLocationPicker(AppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Switch Delivery Region', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...appState.availableLocations.map((loc) => ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.forestGreen),
              title: Text(loc['city'] ?? 'Unknown'),
              onTap: () {
                appState.setTenant(loc['dbName'], loc['city']);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isB2C = state.currentUser?.type == 'b2c' && state.currentUser?.role != 'cash_collector';

    final List<Widget> pages = [
      _buildTasksView(state),
      if (isB2C) const DepositScreen(),
      const AttendanceScreen(),
    ];

    // Clamp index in case user switches mode and index would be out of range
    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    String getTitle() {
      if (state.currentUser?.role == 'cash_collector') return 'Collection';
      if (safeIndex == 0) return 'Deliveries';
      if (isB2C && safeIndex == 1) return 'Wallet';
      return 'Attendance';
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // If not on Home tab (index 0), navigate back to Home
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
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
              content: Text('Press back again to exit Zudo Delivery'),
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
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(getTitle()),
              Text(state.currentCity ?? 'Select Location', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              onPressed: () => _showLocationPicker(state),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Provider.of<AppState>(context, listen: false).logout(),
            ),
          ],
        ),
        body: IndexedStack(
          index: safeIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: AppColors.forestGreen,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Deliveries'),
            if (isB2C) const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Deposit'),
            const BottomNavigationBarItem(icon: Icon(Icons.event_available_outlined), label: 'Attendance'),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksView(AppState state) {
    if (state.isLoading && state.assignedOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Grouping Logic
    final pickupGroups = <String, List<OrderModel>>{};
    final sellers = <String, SellerInfo>{};
    final deliveryOrders = <OrderModel>[];

    for (var order in state.assignedOrders) {
      final status = order.status.toLowerCase();
      if (status == 'out for delivery') {
        deliveryOrders.add(order);
      } else if (status != 'delivered' && status != 'cancelled') {
        // Group by seller for pickups
        for (var seller in order.uniqueSellers) {
          if (!pickupGroups.containsKey(seller.id)) {
            pickupGroups[seller.id] = [];
            sellers[seller.id] = seller;
          }
          if (!pickupGroups[seller.id]!.contains(order)) {
            pickupGroups[seller.id]!.add(order);
          }
        }
      }
    }

    return RefreshIndicator(
      edgeOffset: 0,
      onRefresh: () => state.fetchAssignedOrders(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStats(state),
          const SizedBox(height: 24),
          
          if (pickupGroups.isNotEmpty) ...[
            const Text(
              'PICKUP DELIVERIES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            ...pickupGroups.entries.map((entry) => _SellerPickupCard(
              seller: sellers[entry.key]!,
              orders: entry.value,
            )),
            const SizedBox(height: 24),
          ],

          if (deliveryOrders.isNotEmpty) ...[
            const Text(
              'ORDER DELIVERIES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            ...deliveryOrders.map((order) => _OrderCard(order: order)),
          ],

          if (pickupGroups.isEmpty && deliveryOrders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No active deliveries assigned to you.'),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStats(AppState state) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Active',
            value: (state.assignedOrders.length).toString(),
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Completed',
            value: state.deliveryHistory.length.toString(),
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              if (state.currentUser?.type == 'b2c') {
                setState(() => _selectedIndex = 1);
              }
            },
            child: _StatCard(
              title: 'Wallet',
              value: '₹${state.currentUser?.wallet.toStringAsFixed(2) ?? '0.00'}',
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _SellerPickupCard extends StatelessWidget {
  final SellerInfo seller;
  final List<OrderModel> orders;

  const _SellerPickupCard({required this.seller, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // If only one order, go to its details. If multiple, go to the first one?
          // Ideally we'd show a list, but for now we'll navigate to the first order 
          // or let the driver pick one since OrderDetails now shows the grouped items.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: orders.first)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.store, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(seller.address, style: const TextStyle(color: AppColors.lightText, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${orders.length} ${orders.length == 1 ? 'Order' : 'Orders'}',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 16, color: AppColors.lightText),
                  const SizedBox(width: 8),
                  Text(
                    'Items: ${orders.fold(0, (sum, order) => sum + order.items.where((i) => i.sellerId == seller.id).length)} products',
                    style: const TextStyle(color: AppColors.lightText, fontSize: 13),
                  ),
                  const Spacer(),
                  const Text(
                    'Pick Up Now',
                    style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.forestGreen, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber.substring(order.orderNumber.length - 6)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.lightText),
                  const SizedBox(width: 8),
                  Text(order.customerName, style: const TextStyle(color: AppColors.lightText)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.lightText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.fullAddress,
                      style: const TextStyle(color: AppColors.lightText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                  ),
                  const Text(
                    'Deliver Now',
                    style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.forestGreen, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'out for delivery': color = Colors.blue; break;
      case 'delivered': color = Colors.green; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
