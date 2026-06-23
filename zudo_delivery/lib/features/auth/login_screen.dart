import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginMode { none, b2c, b2b, cashCollector, sales }

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  LoginMode _mode = LoginMode.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().autoFetchLocation();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    final appState = context.read<AppState>();
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

  void _resetFields() {
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;
    final buttonWidth = size.width * 0.85;
    const buttonHeight = 80.0;
    final startOffset = (size.height / 2) - 180.0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Section: Welcome Text (Fixed)
            Positioned(
              top: 40,
              left: 32,
              right: 32,
              child: Opacity(
                opacity: _mode == LoginMode.none ? 1.0 : 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _showLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.forestGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              appState.currentCity ?? (appState.isFetchingLocation ? 'Detecting...' : 'Select Location'),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.forestGreen),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Zudo Delivery\nPartner',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deliver More Earn More',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.lightText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Animated B2C Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastOutSlowIn,
              left: _mode == LoginMode.b2c ? 0 : (_mode == LoginMode.none ? (size.width - buttonWidth) / 2 : -size.width),
              top: _mode == LoginMode.b2c ? 0 : startOffset,
              width: _mode == LoginMode.b2c ? size.width : buttonWidth,
              height: _mode == LoginMode.b2c ? size.height : buttonHeight,
              child: _buildModeButton(
                title: 'B2C DELIVERY',
                subtitle: 'Deliver groceries to customers',
                icon: Icons.motorcycle_rounded,
                color: AppColors.forestGreen,
                mode: LoginMode.b2c,
                appState: appState,
              ),
            ),

            // Animated B2B Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastOutSlowIn,
              left: _mode == LoginMode.b2b ? 0 : (_mode == LoginMode.none ? (size.width - buttonWidth) / 2 : -size.width),
              top: _mode == LoginMode.b2b ? 0 : startOffset + 96.0,
              width: _mode == LoginMode.b2b ? size.width : buttonWidth,
              height: _mode == LoginMode.b2b ? size.height : buttonHeight,
              child: _buildModeButton(
                title: 'B2B DELIVERY',
                subtitle: 'Deliver bulk orders to businesses',
                icon: Icons.local_shipping_rounded,
                color: Colors.orange.shade800,
                mode: LoginMode.b2b,
                appState: appState,
              ),
            ),

            // Animated Cash Collector Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastOutSlowIn,
              left: _mode == LoginMode.cashCollector ? 0 : (_mode == LoginMode.none ? (size.width - buttonWidth) / 2 : -size.width),
              top: _mode == LoginMode.cashCollector ? 0 : startOffset + 192.0,
              width: _mode == LoginMode.cashCollector ? size.width : buttonWidth,
              height: _mode == LoginMode.cashCollector ? size.height : buttonHeight,
              child: _buildModeButton(
                title: 'CASH COLLECTOR',
                subtitle: 'Collect cash from B2B customers',
                icon: Icons.payments_rounded,
                color: Colors.purple.shade700,
                mode: LoginMode.cashCollector,
                appState: appState,
              ),
            ),

            // Animated Sales Associate Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.fastOutSlowIn,
              left: _mode == LoginMode.sales ? 0 : (_mode == LoginMode.none ? (size.width - buttonWidth) / 2 : -size.width),
              top: _mode == LoginMode.sales ? 0 : startOffset + 288.0,
              width: _mode == LoginMode.sales ? size.width : buttonWidth,
              height: _mode == LoginMode.sales ? size.height : buttonHeight,
              child: _buildModeButton(
                title: 'SALES ASSOCIATE',
                subtitle: 'Onboard and place orders for B2B stores',
                icon: Icons.business_center_rounded,
                color: Colors.indigo.shade700,
                mode: LoginMode.sales,
                appState: appState,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required LoginMode mode,
    required AppState appState,
  }) {
    bool isSelected = _mode == mode;

    return GestureDetector(
      onTap: () {
        if (_mode != mode) {
          setState(() {
            _mode = mode;
            _resetFields();
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isSelected ? 0 : 24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isSelected
            ? _buildExpandedForm(title, icon, appState)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildExpandedForm(String title, IconData icon, AppState appState) {
    Color color = _mode == LoginMode.b2c 
        ? AppColors.forestGreen 
        : (_mode == LoginMode.b2b 
            ? Colors.orange.shade800 
            : (_mode == LoginMode.cashCollector 
                ? Colors.purple.shade700 
                : (_mode == LoginMode.sales ? Colors.indigo.shade700 : AppColors.forestGreen)));
    bool isCollector = _mode == LoginMode.cashCollector;

    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                title.split(' ')[0], // Just 'B2C' or 'B2B'
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                onPressed: () => setState(() => _mode = LoginMode.none),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Partner Sign In',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    cursorColor: Colors.black,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: isCollector ? 'Phone Number' : 'Email Address',
                      labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: Icon(isCollector ? Icons.phone_android_rounded : Icons.email_outlined, color: color),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                    ),
                    keyboardType: isCollector ? TextInputType.phone : TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    cursorColor: Colors.black,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: color),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.lightText,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: appState.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: appState.isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Contact administration if you cannot login',
                      style: TextStyle(color: AppColors.lightText, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final appState = context.read<AppState>();
    try {
      bool success = false;
      if (_mode == LoginMode.cashCollector) {
        success = await appState.cashCollectorLogin(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else if (_mode == LoginMode.sales) {
        success = await appState.salesLogin(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await appState.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (success) {
        if (_mode == LoginMode.cashCollector || _mode == LoginMode.sales) {
          // Navigation handled by root
        } else {
          final userType = appState.currentUser?.type;
          final expectedType = _mode == LoginMode.b2c ? 'b2c' : 'b2b';
          print('DEBUG: login success. userType: $userType, expectedType: $expectedType');
          
          if (userType != null && userType.toLowerCase() != expectedType.toLowerCase()) {
            print('DEBUG: type mismatch! logging out.');
            appState.logout();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Incorrect account type. This is for ${expectedType.toUpperCase()} drivers.')),
              );
            }
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}
