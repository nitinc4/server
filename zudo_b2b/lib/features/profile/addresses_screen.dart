import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import 'add_address_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.forestGreen),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressScreen()),
            ),
          ),
        ],
      ),
      body: appState.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : appState.savedAddresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: appState.savedAddresses.length,
              itemBuilder: (context, index) {
                final addr = appState.savedAddresses[index];
                return _buildAddressCard(addr);
              },
            ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddAddressScreen(addressToEdit: addr)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: AppColors.forestGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(addr['label'] ?? addr['name'] ?? 'Address', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.lightText),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (addr['storeName'] != null && addr['storeName'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 14, color: AppColors.forestGreen),
                          const SizedBox(width: 6),
                          Text(addr['storeName'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                        ],
                      ),
                    ),
                  if (addr['customerName'] != null && addr['customerName'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.forestGreen),
                          const SizedBox(width: 6),
                          Text(addr['customerName'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                        ],
                      ),
                    ),
                  if (addr['phone'] != null && addr['phone'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('📞 ${addr['phone']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
                    ),
                  Text(addr['address'] ?? '', style: const TextStyle(color: AppColors.lightText, fontSize: 14)),
                  Text('${addr['city'] ?? ''}, ${addr['pincode'] ?? ''}', style: const TextStyle(color: AppColors.lightText, fontSize: 14)),
                  if (addr['lat'] != null && addr['lng'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'GPS: ${addr['lat'].toStringAsFixed(4)}, ${addr['lng'].toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: AppColors.forestGreen.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteAddress(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          const Text('No saved addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Add an address for faster checkout', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressScreen()),
            ),
            child: const Text('Add New Address'),
          ),
        ],
      ),
    );
  }
}
