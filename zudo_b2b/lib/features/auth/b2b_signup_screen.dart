import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class B2BSignupScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialName;
  const B2BSignupScreen({super.key, this.initialEmail, this.initialName});

  @override
  State<B2BSignupScreen> createState() => _B2BSignupScreenState();
}

class _B2BSignupScreenState extends State<B2BSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _idNumberController = TextEditingController();
  bool _obscurePassword = true;

  String? _storePicUrl;
  String? _docUrl;
  String? _selectedStorePicName;
  String? _selectedDocName;
  String _idType = 'GST'; // GST, PAN, Aadhaar
  
  bool _isUploadingStorePic = false;
  bool _isUploadingDoc = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _pincodeController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool forStorePic) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      setState(() {
        if (forStorePic) {
          _isUploadingStorePic = true;
          _selectedStorePicName = image.name;
        } else {
          _isUploadingDoc = true;
          _selectedDocName = image.name;
        }
      });

      try {
        final url = await ApiService.uploadFile(file);
        if (mounted) {
          setState(() {
            if (forStorePic) {
              _storePicUrl = url;
              _isUploadingStorePic = false;
            } else {
              _docUrl = url;
              _isUploadingDoc = false;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            if (forStorePic) {
              _isUploadingStorePic = false;
              _selectedStorePicName = null;
            } else {
              _isUploadingDoc = false;
              _selectedDocName = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
        }
      }
    }
  }

  Future<void> _pickDoc() async {
    // Allow both PDF and Images for the ID document
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              title: const Text('Upload PDF'),
              onTap: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null) {
                  _handleDocUpload(File(result.files.single.path!), result.files.single.name);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: Colors.blue),
              title: const Text('Upload Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDocUpload(File file, String name) async {
    setState(() {
      _isUploadingDoc = true;
      _selectedDocName = name;
    });

    try {
      final url = await ApiService.uploadFile(file);
      if (mounted) {
        setState(() {
          _docUrl = url;
          _isUploadingDoc = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingDoc = false;
          _selectedDocName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      appBar: AppBar(
        title: const Text('Business Signup', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partner with Zudo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your business to access wholesale pricing.',
              style: TextStyle(color: AppColors.lightText),
            ),
            const SizedBox(height: 32),
            
            // Basic Info
            _buildSectionTitle('Contact Details'),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Contact Person Name', hintText: 'e.g. John Doe'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address', hintText: 'e.g. business@example.com'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            _buildSectionTitle('Business Information'),
            const SizedBox(height: 16),
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name', hintText: 'e.g. Fresh Mart'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pincode (for Sales Mapping)', hintText: 'e.g. 560076'),
            ),
            const SizedBox(height: 24),
            
            // Store Picture
            const Text('Store Picture (Mandatory)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildUploadCard(
              onTap: () => _pickImage(true),
              isUploading: _isUploadingStorePic,
              fileName: _selectedStorePicName,
              url: _storePicUrl,
              icon: Icons.storefront_rounded,
              label: 'Upload Store Photo',
            ),
            
            const SizedBox(height: 40),
            _buildSectionTitle('Identity Verification'),
            const SizedBox(height: 16),
            
            // ID Type Selection
            const Text('Select ID Type', style: TextStyle(fontSize: 14, color: AppColors.lightText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _idType,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  items: ['GST', 'Aadhaar', 'PAN'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _idType = val!;
                      _idNumberController.clear();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _idNumberController,
              decoration: InputDecoration(
                labelText: '$_idType Number',
                hintText: 'Enter your valid $_idType',
              ),
            ),
            const SizedBox(height: 24),
            
            // ID Document
            Text('Upload $_idType Document (PDF or Image)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildUploadCard(
              onTap: _pickDoc,
              isUploading: _isUploadingDoc,
              fileName: _selectedDocName,
              url: _docUrl,
              icon: Icons.badge_outlined,
              label: 'Upload Document',
            ),
            
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: appState.isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: appState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.lightText, letterSpacing: 1.2),
    );
  }

  Widget _buildUploadCard({
    required VoidCallback onTap,
    required bool isUploading,
    required String? fileName,
    required String? url,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        dashPattern: const [8, 4],
        color: AppColors.forestGreen.withValues(alpha: 0.3),
        strokeWidth: 2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              if (isUploading)
                const CircularProgressIndicator(color: AppColors.forestGreen)
              else if (fileName != null) ...[
                Icon(url != null ? Icons.check_circle_rounded : Icons.file_present_rounded, 
                     color: url != null ? AppColors.forestGreen : Colors.orange, size: 40),
                const SizedBox(height: 8),
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(url != null ? 'Success ✓' : 'Uploading...', 
                     style: TextStyle(color: url != null ? AppColors.forestGreen : Colors.orange, fontSize: 11)),
              ] else ...[
                Icon(icon, color: AppColors.forestGreen, size: 40),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(color: AppColors.lightText, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    final appState = context.read<AppState>();
    
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _businessNameController.text.isEmpty ||
        _pincodeController.text.isEmpty ||
        _idNumberController.text.isEmpty ||
        _storePicUrl == null ||
        _docUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory fields and upload documents')),
      );
      return;
    }

    final registrationData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': 'b2b',
      'businessName': _businessNameController.text,
      'pincode': _pincodeController.text.trim(),
      'storePic': _storePicUrl,
      'gstPdf': _docUrl, // Reuse gstPdf field for any ID doc
    };

    if (_idType == 'GST') registrationData['gstNumber'] = _idNumberController.text;
    if (_idType == 'PAN') registrationData['panNumber'] = _idNumberController.text;
    if (_idType == 'Aadhaar') registrationData['aadhaarNumber'] = _idNumberController.text;

    final success = await appState.register(registrationData);
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted for review!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed.')));
    }
  }
}

