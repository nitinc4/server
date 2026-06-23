import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../auth/b2b_login_screen.dart';
import '../profile/addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AppState>().fetchProfile();
      }
    });
  }

  void _pickImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() => _isUploading = true);
      
      try {
        final url = await ApiService.uploadFile(file);
        if (mounted) {
          await context.read<AppState>().updateProfile({'profilePicture': url});
          setState(() => _isUploading = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.kalam(fontWeight: FontWeight.bold, fontSize: 24)),
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
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final user = state.currentUser;
          return RefreshIndicator(
            edgeOffset: 0,
            onRefresh: () => state.fetchProfile(),
            color: AppColors.forestGreen,
            child: user == null
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline, size: 80, color: AppColors.forestGreen),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Welcome to Zudo',
                              style: GoogleFonts.kalam(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Login to track orders, save addresses, and enjoy a personalized shopping experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.lightText, height: 1.5),
                            ),
                            const SizedBox(height: 48),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => B2BLoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Login / Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: kToolbarHeight + MediaQuery.of(context).padding.top + 32,
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ),
                  children: [
                    _buildProfileHeader(context, state),
                    const SizedBox(height: 32),
                    if (user.role == 'b2b') ...[
                      _buildSectionHeader('Business Details'),
                      _buildInfoTile(Icons.business, 'Business Name', user.businessName ?? 'N/A'),
                      _buildInfoTile(Icons.receipt_long, 'GST Number', user.gstNumber ?? 'N/A'),
                      _buildInfoTile(Icons.pin_drop, 'Pincode', user.pincode ?? 'N/A'),
                      _buildInfoTile(Icons.verified, 'Status', user.isVerified ? 'Verified' : (user.isWaitingApproval ? 'Pending Approval' : 'Unverified')),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Your Sales Associate'),
                      if (user.salesAssociate != null) ...[
                        _buildInfoTile(Icons.person, 'Associate Name', user.salesAssociate!['name'] ?? 'N/A'),
                        _buildInfoTile(
                          Icons.email,
                          'Associate Email',
                          user.salesAssociate!['email'] ?? 'N/A',
                          onTap: user.salesAssociate!['email'] != null && user.salesAssociate!['email'].toString().isNotEmpty
                              ? () async {
                                  final email = user.salesAssociate!['email']!.toString().trim();
                                  final Uri launchUri = Uri(
                                    scheme: 'mailto',
                                    path: email,
                                  );
                                  if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri);
                                  }
                                }
                              : null,
                        ),
                        if (user.salesAssociate!['phone'] != null && user.salesAssociate!['phone'].toString().isNotEmpty)
                          _buildInfoTile(
                            Icons.phone,
                            'Associate Phone',
                            user.salesAssociate!['phone']!,
                            onTap: () async {
                              final phone = user.salesAssociate!['phone']!.toString().trim();
                              final Uri launchUri = Uri(
                                scheme: 'tel',
                                path: phone,
                              );
                              if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri);
                              }
                            },
                          ),
                      ] else ...[
                        _buildInfoTile(Icons.person_off, 'Sales Associate', 'No associate allocated yet'),
                      ],
                      const SizedBox(height: 24),
                    ],
                    _buildSectionHeader('Account Settings'),
                    _buildInfoTile(Icons.email, 'Email', user.email),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.forestGreen),
                      title: const Text('Manage Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Add or remove delivery locations'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressesScreen()),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        state.logout();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Logout Account'),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppState state) {
    final user = state.currentUser!;
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
              backgroundImage: user.profilePicture != null 
                ? NetworkImage(ApiConstants.getFullImageUrl(user.profilePicture))
                : null,
              child: user.profilePicture == null 
                ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.tertiary)
                : null,
            ),
            if (_isUploading)
              const Positioned.fill(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _pickImage(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.lightText)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.forestGreen, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.lightText)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

