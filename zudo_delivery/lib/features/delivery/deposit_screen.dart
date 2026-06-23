import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();
  final _otpController = TextEditingController();
  String? _activeDepositId;
  bool _isSubmitting = false;
  bool _showOtpField = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<AppState>(context, listen: false).fetchDepositHistory();
    });
  }


  Future<void> _submitDeposit() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final walletBalance = appState.currentUser?.wallet ?? 0.0;
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot deposit more than your wallet balance (₹${walletBalance.toStringAsFixed(2)})')),
      );
      return;
    }

    if (amount > walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot deposit more than your wallet balance (₹${walletBalance.toStringAsFixed(2)})')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final deposit = await Provider.of<AppState>(context, listen: false).submitDeposit(amount);
      if (mounted) {
        setState(() {
          _activeDepositId = deposit['_id'];
          _showOtpField = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit request created. Please enter the OTP from admin panel.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await Provider.of<AppState>(context, listen: false).verifyDeposit(_activeDepositId!, _otpController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit verified successfully!')),
        );
        _amountController.clear();
        _otpController.clear();
        setState(() {
          _showOtpField = false;
          _activeDepositId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final walletBalance = appState.currentUser?.wallet ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Deposit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(walletBalance),
            const SizedBox(height: 32),
            const Text('New Deposit Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDepositForm(),
            const SizedBox(height: 40),
            const Text('Recent Deposits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDepositHistory(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forestGreen, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT WALLET BALANCE', 
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('₹${balance.toStringAsFixed(2)}', 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Total cash collected to be deposited', 
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDepositForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              enabled: !_showOtpField,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Deposit Amount',
                labelStyle: TextStyle(color: Colors.black),
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
            ),
            if (_showOtpField) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                cursorColor: Colors.black,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Enter OTP from Admin Panel',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : (_showOtpField ? _verifyOtp : _submitDeposit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_showOtpField ? 'Verify OTP' : 'Request OTP', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            if (_showOtpField) 
              TextButton(
                onPressed: () => setState(() => _showOtpField = false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositHistory(AppState appState) {
    if (appState.depositHistory.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            const Text('No deposit history found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appState.depositHistory.length,
      itemBuilder: (context, index) {
        final deposit = appState.depositHistory[index];
        final status = deposit['status'] ?? 'Pending';
        final amount = deposit['amount'] ?? 0;
        final date = DateTime.parse(deposit['createdAt']);

        Color statusColor = Colors.orange;
        if (status == 'Approved') statusColor = Colors.green;
        if (status == 'Rejected') statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => _showDepositDetails(deposit),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == 'Approved' ? Icons.check : (status == 'Rejected' ? Icons.close : Icons.access_time),
                color: statusColor,
              ),
            ),
            title: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDepositDetails(Map<String, dynamic> deposit) {
    final status = deposit['status'] ?? 'Pending';
    final amount = deposit['amount'] ?? 0;
    final date = DateTime.parse(deposit['createdAt']);
    final remarks = deposit['remarks'] ?? 'No remarks';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deposit Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDetailRow('Amount', '₹$amount'),
              _buildDetailRow('Status', status),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(date)),
              _buildDetailRow('Remarks', remarks),
              const SizedBox(height: 24),
              if (status == 'Pending') ...[
                const Text('Verify Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  cursorColor: Colors.black,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Enter 6-digit OTP',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _activeDepositId = deposit['_id'];
                      _verifyOtp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Verify OTP', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
