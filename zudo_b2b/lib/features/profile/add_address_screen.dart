import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'map_location_picker.dart';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? addressToEdit;
  const AddAddressScreen({super.key, this.addressToEdit});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  late TextEditingController _labelController;
  late TextEditingController _storeNameController;
  late TextEditingController _customerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _stateController;
  
  double _lat = 12.9716; 
  double _lng = 77.5946;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.addressToEdit?['label']);
    _storeNameController = TextEditingController(text: widget.addressToEdit?['storeName']);
    _customerNameController = TextEditingController(text: widget.addressToEdit?['customerName']);
    _phoneController = TextEditingController(text: widget.addressToEdit?['phone']);
    _addressController = TextEditingController(text: widget.addressToEdit?['address']);
    _cityController = TextEditingController(text: widget.addressToEdit?['city']);
    _pincodeController = TextEditingController(text: widget.addressToEdit?['pincode']);
    _stateController = TextEditingController(text: widget.addressToEdit?['state']);
    
    if (widget.addressToEdit != null) {
      _lat = widget.addressToEdit!['lat'] ?? 12.9716;
      _lng = widget.addressToEdit!['lng'] ?? 77.5946;
    }

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
          _lat = loc.latitude;
          _lng = loc.longitude;
          
          List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lng);
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

  @override
  void dispose() {
    _labelController.dispose();
    _storeNameController.dispose();
    _customerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      } 

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _isGettingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current location fetched successfully')),
        );
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.addressToEdit != null ? 'Edit Address' : 'Add New Address', 
                   style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.addressToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Home, Office)',
                labelStyle: TextStyle(color: Colors.black),
                hintText: 'Home',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storeNameController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Store Name',
                labelStyle: TextStyle(color: Colors.black),
                hintText: 'Enter store name',
                prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.forestGreen),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerNameController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                labelStyle: TextStyle(color: Colors.black),
                hintText: 'Enter customer name',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.forestGreen),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                labelStyle: TextStyle(color: Colors.black),
                hintText: 'Enter phone number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Full Address',
                labelStyle: TextStyle(color: Colors.black),
              ),
              maxLines: 2,
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
            const Text('GPS Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                      Text('Auto-fills based on map pin', style: TextStyle(fontSize: 12, color: AppColors.lightText)),
                    ],
                  ),
                  _isGettingLocation 
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final Map<String, dynamic>? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapLocationPicker(
                                    initialPosition: LatLng(_lat, _lng),
                                  ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _lat = result['lat'];
                                  _lng = result['lng'];
                                  _pincodeController.text = result['pincode'] ?? '';
                                  _cityController.text = result['city'] ?? '';
                                  _stateController.text = result['state'] ?? '';
                                  if (_addressController.text.isEmpty) {
                                    _addressController.text = result['address'] ?? '';
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Pick on Map'),
                            style: TextButton.styleFrom(foregroundColor: Colors.blue),
                          ),
                        ],
                      ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: appState.isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: appState.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.addressToEdit != null ? 'Update Address' : 'Save Address', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context.read<AppState>().deleteAddress(widget.addressToEdit!['id']);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _saveAddress() async {
    if (_addressController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter full address and city')));
      return;
    }

    final addressData = {
      'label': _labelController.text.isEmpty ? 'Address' : _labelController.text,
      'storeName': _storeNameController.text,
      'customerName': _customerNameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'pincode': _pincodeController.text,
      'state': _stateController.text,
      'lat': _lat,
      'lng': _lng,
    };

    bool success;
    if (widget.addressToEdit != null) {
      // For editing, we need to delete then add (or if we had a dedicated edit API)
      // The current backend doesn't seem to have a dedicated PUT for addresses
      // so we'll delete and re-add for now, or just add if it's new.
      // Wait, let's check if there's a PUT /addresses/:id in auth.js.
      // Checking auth.js... No PUT /addresses/:id.
      
      // I'll delete and then add.
      final addressId = widget.addressToEdit!['id'] ?? widget.addressToEdit!['_id'];
      if (addressId != null) {
        await context.read<AppState>().deleteAddress(addressId.toString());
      }
      success = await context.read<AppState>().addAddress(addressData);
    } else {
      success = await context.read<AppState>().addAddress(addressData);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.addressToEdit != null ? 'Address updated' : 'Address saved'))
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save address')));
    }
  }
}
