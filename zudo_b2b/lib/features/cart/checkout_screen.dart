import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../profile/add_address_screen.dart';
import 'package:geocoding/geocoding.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'Cash at Delivery';
  String? _selectedSlot;
  Map<String, dynamic>? _selectedAddress;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchAddresses();
    });
    _pincodeController.addListener(_onPincodeChanged);
  }

  void _onPincodeChanged() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6) {
      try {
        // 1. Check Serviceability
        await ApiService.findTenantByPincode(pincode);
        
        // 2. Fetch City/State via geocoding
        List<Location> locations = await locationFromAddress(pincode);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            setState(() {
              String rawCity = place.locality ?? '';
              if (rawCity.toLowerCase().contains('bangalore')) rawCity = 'Bengaluru';
              _cityController.text = rawCity;
              _stateController.text = place.administrativeArea ?? '';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pincode $pincode is not serviceable.'))
          );
        }
      }
    }
  }

  void _selectSavedAddress(Map<String, dynamic> addr) {
    setState(() {
      _selectedAddress = addr;
      _addressController.text = addr['address'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _pincodeController.text = addr['pincode'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _phoneController.text = addr['phone'] ?? '';
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appState.savedAddresses.isNotEmpty || true) ...[ // Always show the section to have 'Add Address'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved Addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddAddressScreen()),
                    ).then((_) {
                      if (mounted) context.read<AppState>().fetchAddresses();
                    }),
                    icon: const Icon(Icons.add, size: 18, color: AppColors.forestGreen),
                    label: const Text('Add New', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: appState.savedAddresses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == appState.savedAddresses.length) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddAddressScreen()),
                        ).then((_) {
                          if (mounted) context.read<AppState>().fetchAddresses();
                        }),
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.solid),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: AppColors.forestGreen),
                              ),
                              const SizedBox(height: 8),
                              const Text('Add Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightText)),
                            ],
                          ),
                        ),
                      );
                    }

                    final addr = appState.savedAddresses[index];
                    final isSelected = _selectedAddress != null && (
                      (_selectedAddress?['_id'] != null && _selectedAddress?['_id'] == addr['_id']) ||
                      (_selectedAddress?['id'] != null && _selectedAddress?['id'] == addr['id'])
                    );
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 160,
                      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                      child: GestureDetector(
                        onTap: () => _selectSavedAddress(addr),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.forestGreen : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.forestGreen.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ] : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                addr['label'] ?? addr['name'] ?? 'Address', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: isSelected ? AppColors.forestGreen : Colors.black,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (addr['phone'] != null && addr['phone'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '📞 ${addr['phone']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.forestGreen.withValues(alpha: 0.8) : AppColors.lightText,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                addr['address'] ?? '', 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: isSelected ? Colors.black87 : AppColors.lightText,
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
              const SizedBox(height: 24),
            ],
            const Text('Shipping Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                labelStyle: TextStyle(color: Colors.black),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'House No. / Building / Street',
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: _cityController, 
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'City',
                    labelStyle: TextStyle(color: Colors.black),
                  )
                )),
                const SizedBox(width: 16),
                Expanded(child: TextField(
                  controller: _pincodeController, 
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    labelStyle: TextStyle(color: Colors.black),
                  )
                )),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stateController, 
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'State',
                labelStyle: TextStyle(color: Colors.black),
              )
            ),
            const SizedBox(height: 32),
            const Text('Delivery Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
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
                              color: isSelected ? AppColors.forestGreen.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.forestGreen : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              slotData['label'],
                              style: TextStyle(
                                color: isSelected 
                                    ? AppColors.forestGreen 
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
            const SizedBox(height: 32),
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            _buildPaymentOption('Cash at Delivery', 'Pay with cash at delivery', Icons.payments_outlined),
            _buildPaymentOption('UPI at Delivery', 'Pay via UPI at delivery', Icons.qr_code_scanner_rounded),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: appState.isLoading ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: appState.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Place Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      title: Text(label),
      secondary: Icon(icon),
      value: value,
      groupValue: _paymentMethod,
      onChanged: (val) => setState(() => _paymentMethod = val!),
      activeColor: AppColors.forestGreen,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _handleCheckout() async {
    if (_addressController.text.isEmpty || _cityController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    final appState = context.read<AppState>();
    
    // 1. Verify City Match
    if (_cityController.text.trim().toLowerCase() != appState.currentCity?.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sorry, we only deliver to ${appState.currentCity} in this session.'))
      );
      return;
    }

    // 2. Verify Pincode Serviceability
    try {
      final pincode = _pincodeController.text.trim();
      final data = await ApiService.findTenantByPincode(pincode);
      if (data['dbName'] != appState.currentTenant) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This pincode belongs to a different service area.'))
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery not available at this pincode.'))
      );
      return;
    }

    // 3. Verify Product Stock
    for (var entry in appState.cart.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      try {
        final product = appState.products.firstWhere((p) => p.id == productId);
        if (quantity > product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Insufficient stock for "${product.name}". Available stock: ${product.stock}, but you requested $quantity.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        // If product is not found, continue
      }
    }

    final shippingAddress = {
      'name': context.read<AppState>().currentUser?.name ?? 'Customer',
      'phone': _phoneController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'pincode': _pincodeController.text,
      'state': _stateController.text,
      'lat': _selectedAddress?['lat'] ?? 12.9716,
      'lng': _selectedAddress?['lng'] ?? 77.5946,
    };

    final selectedSlotMap = appState.deliverySlots.firstWhere(
      (slot) => '${slot['startTime']} - ${slot['endTime']}' == _selectedSlot,
      orElse: () => <String, dynamic>{},
    );

    final success = await appState.placeOrder(
      shippingAddress,
      _paymentMethod,
      deliverySlot: selectedSlotMap.isNotEmpty ? selectedSlotMap : null,
    );
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to place order. Try again.')));
    }
  }
}
