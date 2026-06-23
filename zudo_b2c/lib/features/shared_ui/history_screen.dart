import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/services/invoice_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'live_tracking_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text('Order History', style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
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
                onRefresh: () => state.fetchOrders(),
                color: AppColors.forestGreen,
                child: state.history.isEmpty 
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 100,
                        ),
                        child: _buildEmptyState(context),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
                        left: 20,
                        right: 20,
                        bottom: 120, // Padding for bottom nav
                      ),
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final order = state.history[index];
                        final date = DateTime.parse(order['createdAt'] ?? DateTime.now().toIso8601String());
                        final itemsList = order['items'] as List? ?? [];
                        final itemsCount = itemsList.fold(0, (a, b) => a + ((b['quantity'] ?? 0) as int));

                        return GestureDetector(
                          onTap: () => _showOrderDetails(context, order),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('#${(order['_id'] ?? 'UNK').toString().toUpperCase().substring(math.max(0, (order['_id'] ?? 'UNK').toString().length - 8))}', 
                                             style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), 
                                             style: const TextStyle(color: AppColors.lightText, fontSize: 12)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildStatusBadge('Order', order['orderStatus'], _getStatusColor(order['orderStatus'])),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$itemsCount items', style: const TextStyle(color: AppColors.lightText)),
                                    Text('₹${(order['totalAmount'] ?? 0).toDouble().toStringAsFixed(2)}', 
                                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.tertiary)),
                                  ],
                                ),
                                if (order['deliveryOtp'] != null && order['orderStatus'] != 'Delivered' && order['orderStatus'] != 'Cancelled') ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.forestGreen.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.lock_outline, color: AppColors.forestGreen, size: 16),
                                        const SizedBox(width: 8),
                                        const Text('Delivery OTP: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text(
                                          order['deliveryOtp'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.forestGreen, letterSpacing: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String? status, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.lightText)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            (status ?? 'Pending').toString().toUpperCase(), 
            style: TextStyle(
              color: color, 
              fontSize: 9, 
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5
            )
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Delivered':
        return AppColors.forestGreen;
      case 'Shipped':
        return Colors.blue;
      case 'Out for Delivery':
        return Colors.orange;
      case 'Pending':
        return Colors.amber;
      case 'Cancelled':
        return Colors.red;
      default:
        return AppColors.lightText;
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'Paid':
        return AppColors.forestGreen;
      case 'Pending':
        return Colors.amber;
      case 'Failed':
        return Colors.red;
      case 'Refunded':
        return Colors.purple;
      default:
        return AppColors.lightText;
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final itemsList = order['items'] as List? ?? [];
    final address = order['shippingAddress'] as Map<String, dynamic>? ?? {};
    
    final deliveryLat = address['lat'] != null ? (address['lat'] as num).toDouble() : null;
    final deliveryLng = address['lng'] != null ? (address['lng'] as num).toDouble() : null;
    
    double? storeLat;
    double? storeLng;
    if (itemsList.isNotEmpty) {
      final seller = itemsList[0]['seller'];
      if (seller != null) {
        storeLat = seller['lat'] != null ? (seller['lat'] as num).toDouble() : null;
        storeLng = seller['lng'] != null ? (seller['lng'] as num).toDouble() : null;
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(2)))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order Details', style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
                IconButton(
                  onPressed: () async {
                    final savedPath = await InvoiceService.generateAndDownloadInvoice(order);
                    if (savedPath != null && context.mounted) {
                      final filename = savedPath.split('/').last;
                      _showToast(context, 'invoice saved to downloads $filename');
                    } else if (context.mounted) {
                      _showToast(context, 'Failed to save invoice');
                    }
                  },
                  icon: const Icon(Icons.download_rounded, color: AppColors.forestGreen),
                  tooltip: 'Download Invoice',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${(order['_id'] ?? '').toString().toUpperCase()}', style: const TextStyle(color: AppColors.lightText, fontSize: 12, fontFamily: 'monospace')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['orderStatus']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (order['orderStatus'] ?? 'Pending').toString().toUpperCase(), 
                    style: TextStyle(color: _getStatusColor(order['orderStatus']), fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payment, size: 14, color: AppColors.lightText),
                const SizedBox(width: 8),
                Text('Method: ${order['paymentMethod'] ?? 'N/A'}', style: const TextStyle(color: AppColors.lightText, fontSize: 13)),
              ],
            ),
            if (order['deliveryOtp'] != null && order['orderStatus'] != 'Delivered' && order['orderStatus'] != 'Cancelled') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.forestGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.forestGreen, size: 20),
                    const SizedBox(width: 12),
                    const Text('Delivery OTP: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      order['deliveryOtp'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.forestGreen, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: itemsList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = itemsList[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: item['image'] != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['image'], width: 40, height: 40, fit: BoxFit.cover))
                        : null,
                    title: Text(item['name'] ?? 'Unknown Product'),
                    subtitle: Text('Qty: ${item['quantity']}'),
                    trailing: Text('₹${((item['price'] ?? 0) * (item['quantity'] ?? 0)).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '${address['address'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}', 
              style: const TextStyle(color: AppColors.lightText)
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: TextStyle(fontSize: 16)),
                Text('₹${(order['totalAmount'] ?? 0).toDouble().toStringAsFixed(2)}', 
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.tertiary)),
              ],
            ),

            if (order['orderStatus'] == 'Delivered') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReturnDialog(context, order['_id'], itemsList);
                  },
                  icon: const Icon(Icons.assignment_return_rounded, color: Colors.redAccent),
                  label: const Text('Return Items', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
            
            if (order['orderStatus'] == 'Picked Up' || order['orderStatus'] == 'Out for Delivery') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingScreen(
                          orderId: order['_id'],
                          initialStatus: order['orderStatus'],
                          storeLat: storeLat,
                          storeLng: storeLng,
                          deliveryLat: deliveryLat,
                          deliveryLng: deliveryLng,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, color: Colors.white),
                  label: const Text('Track Live Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(BuildContext context, String orderId, List<dynamic> itemsList) {
    final eligibleItems = itemsList.where((item) => (item['returnStatus'] ?? 'None') == 'None').toList();
    if (eligibleItems.isEmpty) {
      _showToast(context, 'No items eligible for return.');
      return;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    final needsBankDetails = appState.currentUser?.bankDetails == null;

    final TextEditingController commentController = TextEditingController();
    final TextEditingController accountNameController = TextEditingController();
    final TextEditingController accountNumberController = TextEditingController();
    final TextEditingController ifscCodeController = TextEditingController();
    final TextEditingController bankNameController = TextEditingController();

    String selectedReason = 'Defective Product';
    String? selectedItemId = eligibleItems.first['_id'];
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Return Request', style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95, // Make wider
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true, // Handle long text
                    value: selectedItemId,
                    items: eligibleItems.map((item) => DropdownMenuItem<String>(
                      value: item['_id'],
                      child: Text(
                        item['name'] ?? 'Unknown Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedItemId = v),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason for return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedReason,
                    items: [
                      'Defective Product',
                      'Wrong Item Received',
                      'Quality not as expected',
                      'Expired Product',
                      'Other'
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedReason = v!),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Additional comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Attach a photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        setState(() => selectedImage = File(photo.path));
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
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded, color: AppColors.lightText),
                                SizedBox(height: 4),
                                Text('Click to take photo', style: TextStyle(fontSize: 12, color: AppColors.lightText)),
                              ],
                            ),
                    ),
                  ),
                  if (needsBankDetails) ...[
                    const SizedBox(height: 24),
                    const Text('Bank Details for Refund', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    const SizedBox(height: 12),
                    TextField(controller: accountNameController, decoration: InputDecoration(hintText: 'Account Holder Name', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 8),
                    TextField(controller: accountNumberController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Account Number', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 8),
                    TextField(controller: ifscCodeController, decoration: InputDecoration(hintText: 'IFSC Code', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 8),
                    TextField(controller: bankNameController, decoration: InputDecoration(hintText: 'Bank Name', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            Consumer<AppState>(
              builder: (context, state, _) => ElevatedButton(
                onPressed: state.isLoading || selectedItemId == null
                  ? null 
                  : () async {
                    if (needsBankDetails) {
                      if (accountNameController.text.isEmpty || accountNumberController.text.isEmpty || ifscCodeController.text.isEmpty || bankNameController.text.isEmpty) {
                        _showToast(context, 'Please fill in all bank details for your refund');
                        return;
                      }
                      await state.updateProfile({
                        'bankDetails': {
                          'accountName': accountNameController.text,
                          'accountNumber': accountNumberController.text,
                          'ifscCode': ifscCodeController.text,
                          'bankName': bankNameController.text,
                        }
                      });
                    }

                    final success = await state.returnOrderItem(
                      orderId: orderId,
                      itemId: selectedItemId!,
                      reason: selectedReason,
                      comment: commentController.text,
                      imageFile: selectedImage,
                    );
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      _showToast(context, 'Return request submitted successfully!');
                    }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                ),
                child: state.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
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
                    child: Icon(Icons.history_rounded, 
                               size: 64, 
                               color: AppColors.forestGreen),
                  ),
                  const SizedBox(height: 32),
                  const Text('No order history', 
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  const SizedBox(height: 12),
                  const Text('Your past orders will appear here once you place them.', 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: AppColors.lightText, fontSize: 15, height: 1.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

