import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  color: AppColors.forestGreen,
                  size: 80,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Verification Pending',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Our team is reviewing your documents. This usually takes 24-48 hours. We will notify you once your account is activated.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: AppColors.lightText,
                    ),
                textAlign: TextAlign.center,
              ),
              if (context.watch<AppState>().currentUser?.role == 'b2b') ...[
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Business Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            context.watch<AppState>().currentUser?.businessName ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GST Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            context.watch<AppState>().currentUser?.gstNumber ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().fetchProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking verification status...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Refresh Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              // Testing Bypass Button
              TextButton(
                onPressed: () {
                  context.read<AppState>().bypassApproval();
                },
                child: const Text('Bypass for Testing', style: TextStyle(color: AppColors.lightText)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<AppState>().logout();
                },
                child: const Text('Logout and try B2C'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
