import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng initialPosition;
  const MapLocationPicker({super.key, this.initialPosition = const LatLng(12.9716, 77.5946)});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _currentPosition;
  GoogleMapController? _mapController;
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });
    
    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
  }

  Future<void> _handleConfirm() async {
    setState(() => _isVerifying = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(_currentPosition.latitude, _currentPosition.longitude);
      if (placemarks.isEmpty) throw 'Could not determine address';

      Placemark place = placemarks.first;
      String pincode = place.postalCode ?? '';
      String rawCity = place.locality ?? '';
      if (rawCity.toLowerCase().contains('bangalore')) rawCity = 'Bengaluru';
      String city = rawCity;
      String state = place.administrativeArea ?? '';

      if (pincode.isEmpty) throw 'Pincode not found for this location';

      // Check serviceability
      try {
        await ApiService.findTenantByPincode(pincode);
        // If successful, return the data
        if (mounted) {
          Navigator.pop(context, {
            'lat': _currentPosition.latitude,
            'lng': _currentPosition.longitude,
            'pincode': pincode,
            'city': city,
            'state': state,
            'address': '${place.name}, ${place.street}, ${place.subLocality}'
          });
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unserviceable Location'),
              content: Text('Sorry, we don\'t provide services at $pincode ($city) yet.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Delivery Location', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _currentPosition = position.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35), // Offset for pin tip
              child: Icon(Icons.location_on, color: AppColors.forestGreen, size: 45),
            ),
          ),
          if (_isLoading || _isVerifying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const CircularProgressIndicator(color: AppColors.forestGreen),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _determinePosition,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: AppColors.forestGreen),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isVerifying 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
