import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import 'b2b_signup_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class B2BLoginScreen extends StatefulWidget {
  const B2BLoginScreen({super.key});

  @override
  State<B2BLoginScreen> createState() => _B2BLoginScreenState();
}

class _B2BLoginScreenState extends State<B2BLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _isFetchingLocation = false;
  String? _errorLocation;
  String? _autoDetectedPincode;
  bool _wasManuallySelected = false;

  @override
  void initState() {
    super.initState();
    _autoFetchLocation();
    context.read<AppState>().fetchAvailableLocations();
  }

  Future<void> _autoFetchLocation({bool force = false}) async {
    if (!force && context.read<AppState>().currentTenant != null) {
      if (mounted) {
        setState(() {
          _wasManuallySelected = true;
          _isFetchingLocation = false;
        });
      }
      return;
    }

    setState(() {
      _isFetchingLocation = true;
      _errorLocation = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied.';
      }
      if (permission == LocationPermission.deniedForever) throw 'Location permissions are permanently denied.';

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        String? pincode = placemarks[0].postalCode;
        if (pincode != null) {
          _autoDetectedPincode = pincode;
          _pincodeController.text = pincode;
          _wasManuallySelected = false;
          final served = await context.read<AppState>().fetchTenantByPincode(pincode);
          if (!served && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unserved Location')));
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorLocation = e.toString());
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _showLocationPicker() {
    final appState = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Your City', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...appState.availableLocations.map((loc) => ListTile(
                title: Text(loc['city'] ?? ''),
                trailing: appState.currentCity == loc['city'] ? const Icon(Icons.check_circle, color: Colors.orange) : null,
                onTap: () {
                  _wasManuallySelected = true;
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
                      
                      _wasManuallySelected = false;
                      _autoDetectedPincode = pc;
                      Navigator.pop(context);
                      final served = await appState.fetchTenantByPincode(pc);
                      if (!served && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unserved Location')));
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isFetchingLocation ? null : () {
                    Navigator.pop(context);
                    _autoFetchLocation(force: true);
                  },
                  icon: const Icon(Icons.my_location, color: Colors.black),
                  label: const Text('Use Current Location', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFormAction(VoidCallback action) {
    if (_isFetchingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, location is being fetched')),
      );
      return;
    }
    
    if (context.read<AppState>().currentTenant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sorry, we are not in this location yet')),
      );
      return;
    }

    action();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final appState = context.read<AppState>();
    final success = await appState.login(_emailController.text, _passwordController.text);
    
    if (success) {
      if (appState.currentUser?.role != 'b2b') {
        appState.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No B2B account found with these credentials.')),
          );
        }
      } else {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials or server error')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final appState = context.read<AppState>();
    final result = await appState.signInWithGoogle('b2b');

    if (result == null) return;

    if (result['newUser'] == true) {
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => B2BSignupScreen(
            initialEmail: result['email'],
            initialName: result['name'],
          ),
        ));
      }
    } else if (result.containsKey('token')) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Picker
              GestureDetector(
                onTap: _showLocationPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      if (_isFetchingLocation)
                        const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                      else
                        Text(
                          _wasManuallySelected 
                            ? (appState.currentCity ?? 'Select Location')
                            : (_autoDetectedPincode ?? appState.currentCity ?? 'Select Location'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.lightText, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.business_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 32),
              Text(
                'Business\nWholesale',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Access exclusive wholesale prices and bulk ordering.',
                style: TextStyle(color: AppColors.lightText, fontSize: 16),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Business Email / ID',
                  labelStyle: TextStyle(color: Colors.black),
                  floatingLabelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  prefixIcon: Icon(Icons.business_center_outlined, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black),
                  floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.black54),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.lightText,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: appState.isLoading ? null : () => _onFormAction(_handleLogin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isFetchingLocation || appState.currentTenant == null) ? Colors.grey : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: appState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Login as Business', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: appState.isLoading ? null : () => _onFormAction(_handleGoogleSignIn),
                  icon: Image.network('https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png', height: 24),
                  label: const Text('Sign in with Google', style: TextStyle(fontSize: 16, color: AppColors.darkText)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: (_isFetchingLocation || appState.currentTenant == null) ? Colors.grey.shade100 : null,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: appState.isLoading ? null : () => _onFormAction(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const B2BSignupScreen()),
                    );
                  }),
                  child: const Text(
                    'Don\'t have a business account? Register',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
