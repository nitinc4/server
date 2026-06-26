import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/services/api_service.dart';

Future<BitmapDescriptor> getBytesFromIcon(IconData iconData, Color color, int width) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color = color;
  final double radius = width / 2;

  canvas.drawCircle(Offset(radius, radius), radius, paint);

  TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
  textPainter.text = TextSpan(
    text: String.fromCharCode(iconData.codePoint),
    style: TextStyle(
      fontSize: width * 0.6,
      fontFamily: iconData.fontFamily,
      package: iconData.fontPackage,
      color: Colors.white,
    ),
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((width - textPainter.width) / 2, (width - textPainter.height) / 2),
  );

  final img = await pictureRecorder.endRecording().toImage(width, width);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}

class LiveTrackingScreen extends StatefulWidget {
  final String orderId;
  final String initialStatus;
  final double? storeLat;
  final double? storeLng;
  final double? deliveryLat;
  final double? deliveryLng;
  
  const LiveTrackingScreen({
    super.key,
    required this.orderId,
    required this.initialStatus,
    this.storeLat,
    this.storeLng,
    this.deliveryLat,
    this.deliveryLng,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _timer;
  bool _isLoading = true;
  bool _hasError = false;
  
  LatLng? _driverLatLng;
  String? _driverName;
  String? _driverPhone;
  String _currentStatus = '';

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _storeIcon;
  BitmapDescriptor? _deliveryIcon;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _createMarkers();
    _fetchLocation();
    
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchLocation();
    });
  }

  Future<void> _createMarkers() async {
    _driverIcon = await getBytesFromIcon(Icons.two_wheeler_rounded, AppColors.forestGreen, 100);
    _storeIcon = await getBytesFromIcon(Icons.storefront_rounded, Colors.blueAccent, 90);
    _deliveryIcon = await getBytesFromIcon(Icons.home_rounded, Colors.deepOrangeAccent, 90);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final token = appState.token;
    if (token == null) return;

    try {
      final data = await ApiService.getDriverLocation(token, widget.orderId);
      final double? lat = data['lat'] != null ? (data['lat'] as num).toDouble() : null;
      final double? lng = data['lng'] != null ? (data['lng'] as num).toDouble() : null;

      if (lat != null && lng != null) {
        final newLatLng = LatLng(lat, lng);
        setState(() {
          _driverLatLng = newLatLng;
          _driverName = data['driverName'];
          _driverPhone = data['driverPhone'];
          _hasError = false;
          _isLoading = false;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching driver location: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _callDriver() async {
    if (_driverPhone == null || _driverPhone!.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: _driverPhone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {};
    
    if (widget.storeLat != null && widget.storeLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('store'),
          position: LatLng(widget.storeLat!, widget.storeLng!),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: _storeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (widget.deliveryLat != null && widget.deliveryLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(widget.deliveryLat!, widget.deliveryLng!),
          infoWindow: const InfoWindow(title: 'Delivery Destination'),
          icon: _deliveryIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    if (_driverLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLatLng!,
          infoWindow: InfoWindow(title: _driverName ?? 'Zudo Delivery Executive'),
          icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking',
          style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: AppColors.forestGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Google Map Background
          _driverLatLng != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _driverLatLng!,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: markers,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text(
                      'Awaiting driver\'s live signal...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),

          // Top Info Banner for Offline status
          if (_hasError)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.orange[800]?.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.signal_wifi_off_outlined, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Driver location signal is currently offline. Rest assured, your order is safely on the way!',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Sheet Panel (Glassmorphic details card)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white.withOpacity(0.95),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge and Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentStatus.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'ID: #${widget.orderId.substring(widget.orderId.length - 6).toUpperCase()}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Driver info
                    if (_driverName != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.forestGreen.withOpacity(0.1),
                            radius: 24,
                            child: const Icon(Icons.person, color: AppColors.forestGreen),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _driverName!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const Text(
                                  'Zudo Delivery Professional',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (_driverPhone != null)
                            IconButton(
                              onPressed: _callDriver,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              icon: const Icon(Icons.phone),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: AppColors.forestGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentStatus == 'Out for Delivery'
                                ? 'Your package is out for delivery and will arrive shortly.'
                                : 'Driver has picked up your package and is starting the route.',
                            style: const TextStyle(color: AppColors.lightText, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              ),
            ),
        ],
      ),
    );
  }
}
