import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../orders/order_model.dart';
import '../../core/services/invoice_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _hasCalled = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: OrderDetailsScreen building for order ${widget.order.id} with status: ${widget.order.status}');
    final appState = Provider.of<AppState>(context, listen: false);
    final isCollector = appState.currentUser?.role == 'cash_collector';

    if (isCollector) {
      return _buildCollectorView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Generate Invoice',
            onPressed: () async {
              final savedPath = await InvoiceService.generateAndDownloadInvoice(widget.order);
              if (savedPath != null && context.mounted) {
                final filename = savedPath.split('/').last;
                _showToast(context, 'invoice saved to downloads $filename');
              } else if (context.mounted) {
                _showToast(context, 'Failed to save invoice');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSection(context),
            const SizedBox(height: 24),
            _buildPickupSection(context),
            const SizedBox(height: 24),
            _buildItemsSection(context),
            const SizedBox(height: 24),
            _buildPersonnelSection(context),
            const SizedBox(height: 24),
            _buildStatusUpdateSection(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildCollectorView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Generate Invoice',
            onPressed: () async {
              final savedPath = await InvoiceService.generateAndDownloadInvoice(widget.order);
              if (savedPath != null && context.mounted) {
                final filename = savedPath.split('/').last;
                _showToast(context, 'invoice saved to downloads $filename');
              } else if (context.mounted) {
                _showToast(context, 'Failed to save invoice');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSection(context),
            const SizedBox(height: 24),
            _buildCollectionSummary(context),
            const SizedBox(height: 24),
            _buildItemsSection(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildCollectorActions(context),
    );
  }

  Widget _buildCollectionSummary(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('AMOUNT TO COLLECT', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('₹${widget.order.totalAmount}', 
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.purple.shade900)),
            const SizedBox(height: 24),
            const Text('Scan QR for UPI Payment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: QrImageView(
                  data: 'upi://pay?pa=zudo@upi&pn=Zudo&am=${widget.order.totalAmount}&cu=INR',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('UPI ID: zudo@upi', style: TextStyle(color: Colors.purple.shade300, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectorActions(BuildContext context) {
    final isPaid = widget.order.paymentStatus == 'Completed';
    
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(top: BorderSide(color: Colors.green.shade100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            Text('PAYMENT COLLECTED', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 16, letterSpacing: 0.5)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _confirmCollection(context),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Confirm Cash Collection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CUSTOMER INFO',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey)),
            const SizedBox(height: 12),
            Text(widget.order.customerName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.forestGreen),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.order.fullAddress)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, color: AppColors.forestGreen),
                const SizedBox(width: 12),
                Text(widget.order.customerPhone),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _hasCalled = true;
                    });
                    final Uri telLaunchUri = Uri(
                      scheme: 'tel',
                      path: widget.order.customerPhone,
                    );
                    if (await canLaunchUrl(telLaunchUri)) {
                      await launchUrl(telLaunchUri);
                    }
                  },
                  icon: const Icon(Icons.call, color: Colors.blue),
                ),
              ],
            ),
            if (widget.order.deliverySlot != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.forestGreen),
                  const SizedBox(width: 12),
                  Text(
                    'Delivery Slot: ${widget.order.deliverySlot!['startTime']} - ${widget.order.deliverySlot!['endTime']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickupSection(BuildContext context) {
    if (!(widget.order.status.toLowerCase() == 'assigned' || 
          widget.order.status.toLowerCase() == 'pending' ||
          widget.order.status.toLowerCase() == 'accepted' ||
          widget.order.status.toLowerCase() == 'confirmed' ||
          widget.order.status.toLowerCase() == 'shipped' ||
          widget.order.status.toLowerCase() == 'return driver assigned' ||
          widget.order.status.toLowerCase() == 'return pickup')) {
      
      // If already picked up, show delivery section
      if (widget.order.status.toLowerCase() == 'out for delivery' || 
          widget.order.status.toLowerCase() == 'picked up' ||
          widget.order.status.toLowerCase() == 'out for return' ||
          widget.order.status.toLowerCase() == 'return picked up') {
        return _buildDeliverySection(context);
      }
      return const SizedBox.shrink();
    }

    final sellers = widget.order.uniqueSellers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PICKUP LOCATIONS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey)),
        const SizedBox(height: 12),
        ...sellers.map((seller) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront, color: AppColors.forestGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(seller.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    if (seller.phone != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.blue, size: 20),
                        onPressed: () => launchUrl(Uri.parse('tel:${seller.phone}')),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(seller.address, style: const TextStyle(color: AppColors.lightText, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=${seller.lat},${seller.lng}';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Navigate to Pickup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                      side: const BorderSide(color: AppColors.forestGreen),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
        const SizedBox(height: 8),
        // Pickup Code Verification
        Card(
          color: AppColors.forestGreen.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PICKUP VERIFICATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.forestGreen)),
                const SizedBox(height: 12),
                if (!widget.order.isReturn)
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Enter Pickup Code (OTP)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (!widget.order.isReturn)
                  const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPickup(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(widget.order.isReturn ? 'Mark as Picked Up' : 'Verify & Pick Up All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DELIVERY',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url =
                      'https://www.google.com/maps/dir/?api=1&destination=${widget.order.lat},${widget.order.lng}';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Navigate to Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  side: const BorderSide(color: AppColors.forestGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<AppState>(
              builder: (context, state, _) {
                final isB2B = state.currentUser?.type == 'b2b';
                final isPaid = widget.order.paymentStatus == 'Completed';
                
                if (!isB2B && !isPaid) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please collect payment before verifying delivery.',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DELIVERY VERIFICATION',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey)),
                    const SizedBox(height: 12),
                    if (!widget.order.isReturn)
                      TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Enter Delivery OTP',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    if (!widget.order.isReturn)
                      const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyDelivery(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(widget.order.isReturn ? 'Mark as Returned' : 'Verify & Deliver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context) {
    final groupedItems = widget.order.itemsBySeller;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER ITEMS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey)),
        const SizedBox(height: 12),
        ...groupedItems.entries.map((entry) {
          final sellerId = entry.key;
          final items = entry.value;
          final sellerName = items.first.sellerName ?? 'Seller';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: AppColors.lightText),
                    const SizedBox(width: 8),
                    Text(sellerName.toUpperCase(), 
                         style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lightText, letterSpacing: 0.5)),
                  ],
                ),
              ),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      Image.network(item.image!, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.shopping_bag_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Qty: ${item.quantity}',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text('₹${item.price}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
              const Divider(),
            ],
          );
        }),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('₹${widget.order.totalAmount}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen)),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, state, _) {
            final isB2B = state.currentUser?.type == 'b2b';
            if (isB2B) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'B2B Mode: Payment will be collected by a cash collector.',
                        style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildPersonnelSection(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isB2B = appState.currentUser?.type == 'b2b';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ASSIGNED PERSONNEL',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildPersonnelRow(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery Driver',
                name: widget.order.driver?['name'] ?? 'Not Assigned',
                phone: widget.order.driver?['phone'],
                color: Colors.orange.shade800,
              ),
              if (isB2B) ...[
                const Divider(height: 24),
                _buildPersonnelRow(
                  icon: Icons.payments_outlined,
                  label: 'Cash Collector',
                  name: widget.order.cashCollector?['name'] ?? 'Not Assigned',
                  phone: widget.order.cashCollector?['phone'],
                  color: Colors.purple.shade700,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonnelRow({
    required IconData icon,
    required String label,
    required String name,
    String? phone,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (phone != null)
                Text(phone, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        ),
        if (phone != null)
          IconButton(
            icon: const Icon(Icons.phone_in_talk_outlined, size: 20, color: Colors.blue),
            onPressed: () => launchUrl(Uri.parse('tel:$phone')),
          ),
      ],
    );
  }

  Widget _buildStatusUpdateSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER STATUS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Text('Current Status: ${widget.order.status.toUpperCase()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    String nextActionText = '';
    String nextStatus = '';
    bool canUpdate = true;
    final appState = Provider.of<AppState>(context, listen: false);
    final isB2B = appState.currentUser?.type == 'b2b';
    final isB2C = !isB2B;

    switch (widget.order.status.toLowerCase()) {
      case 'shipped':
      case 'picked up':
      case 'out for delivery':
      case 'return picked up':
        if (isB2C && widget.order.paymentStatus != 'Completed') {
          nextActionText = 'Collect Payment';
          nextStatus = 'PAYMENT_POPUP';
        } else {
          // If already paid or B2B, allow marking as delivered via OTP section
          canUpdate = false;
        }
        break;
      default:
        canUpdate = false;
    }

    if (!canUpdate) return const SizedBox.shrink();

    final isCollector = appState.currentUser?.role == 'cash_collector';

    if (isCollector) {
      if (widget.order.paymentStatus == 'Completed') return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmCollection(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Cash Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          if (_hasCalled) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(context, 'Cancelled'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  elevation: 0,
                ),
                child: const Text('Cancel Order'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () => nextStatus == 'PAYMENT_POPUP' 
                  ? _showPaymentPopup(context) 
                  : _updateStatus(context, nextStatus),
              child: Text(nextActionText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPickup(BuildContext context) async {
    if (widget.order.isReturn) {
      print('DEBUG: Bypassing pickup OTP for return order');
      await _updateStatus(context, 'Return Picked Up');
      return;
    }

    final enteredCode = _otpController.text.trim();
    final expectedCode = widget.order.pickupCode?.trim();

    print('DEBUG: Verifying pickup. Entered: "$enteredCode", Expected: "$expectedCode"');

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the pickup code')),
      );
      return;
    }

    if (expectedCode != null && enteredCode == expectedCode) {
      print('DEBUG: Pickup code match successful');
      _otpController.clear();
      await _updateStatus(context, widget.order.isReturn ? 'Return Picked Up' : 'Out for Delivery');
    } else {
      print('DEBUG: Pickup code mismatch');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid pickup code. Expected: $expectedCode')),
      );
    }
  }

  Future<void> _verifyDelivery(BuildContext context) async {
    if (widget.order.isReturn) {
      print('DEBUG: Bypassing delivery OTP for return order');
      await _updateStatus(context, 'Returned');
      return;
    }

    final enteredOtp = _otpController.text.trim();
    final expectedOtp = widget.order.deliveryOtp?.trim();

    print('DEBUG: Verifying delivery. Entered: "$enteredOtp", Expected: "$expectedOtp"');

    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the delivery OTP')),
      );
      return;
    }

    if (expectedOtp != null && enteredOtp == expectedOtp) {
      print('DEBUG: Delivery OTP match successful');
      _otpController.clear();
      await _updateStatus(context, widget.order.isReturn ? 'Returned' : 'Delivered');
    } else {
      print('DEBUG: Delivery OTP mismatch');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid delivery OTP. Expected: $expectedOtp')),
      );
    }
  }

  Future<void> _showPaymentPopup(BuildContext context) async {
    File? pickedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan & Pay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Center(
                child: QrImageView(
                  data: 'upi://pay?pa=zudo@upi&pn=Zudo&am=${widget.order.totalAmount}&cu=INR',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 12),
              Text('Amount: ₹${widget.order.totalAmount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.forestGreen)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Upload Payment Proof', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setModalState(() => pickedImage = File(image.path));
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: pickedImage != null 
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(pickedImage!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                          Text('Take a Picture', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (pickedImage == null || isUploading) ? null : () async {
                    setModalState(() => isUploading = true);
                    try {
                      final appState = Provider.of<AppState>(ctx, listen: false);
                      final url = await appState.uploadFile(pickedImage!);
                      await appState.updatePaymentInfo(widget.order.id, url);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Payment marked as paid!')));
                        setState(() {}); // Refresh the current screen
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      setModalState(() => isUploading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isUploading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Mark as Paid (Online)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : () async {
                    setModalState(() => isUploading = true);
                    try {
                      final appState = Provider.of<AppState>(ctx, listen: false);
                      // Passing null as screenshotUrl indicates cash payment
                      await appState.updatePaymentInfo(widget.order.id, null as dynamic); 
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Payment marked as Cash Paid!')));
                        setState(() {}); // Refresh the current screen
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    } finally {
                      setModalState(() => isUploading = false);
                    }
                  },
                  icon: const Icon(Icons.money),
                  label: const Text('Paid by Cash'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forestGreen,
                    side: const BorderSide(color: AppColors.forestGreen),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCollection(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Collection'),
        content: Text('Have you collected ₹${widget.order.totalAmount} from the customer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Collected', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        // Using existing updatePaymentInfo with null as proof indicates cash
        await appState.updatePaymentInfo(widget.order.id, null as dynamic);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collection confirmed!')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      if (status == 'Cancelled') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to cancel this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      await Provider.of<AppState>(context, listen: false)
          .updateOrderStatus(widget.order.id, status);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }
}

