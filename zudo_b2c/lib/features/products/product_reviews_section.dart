import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';

class ProductReviewsSection extends StatefulWidget {
  final String productId;
  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final data = await ApiService.getProductReviews(widget.productId);
      setState(() {
        _reviews = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showWriteReviewDialog() {
    int rating = 5;
    final commentController = TextEditingController();
    List<String> uploadedMedia = [];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  )),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                      allowMultiple: true,
                    );
                    if (result != null) {
                      setDialogState(() => isUploading = true);
                      try {
                        for (var file in result.files) {
                          if (file.path != null) {
                            final url = await ApiService.uploadFile(File(file.path!));
                            if (url != null) {
                              setDialogState(() => uploadedMedia.add(url));
                            }
                          }
                        }
                      } finally {
                        setDialogState(() => isUploading = false);
                      }
                    }
                  },
                  child: DottedBorder(
                    color: AppColors.forestGreen.withValues(alpha: 0.3),
                    strokeWidth: 2,
                    dashPattern: const [8, 4],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (isUploading)
                            const CircularProgressIndicator(strokeWidth: 2)
                          else ...[
                            const Icon(Icons.cloud_upload_outlined, color: AppColors.forestGreen, size: 32),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload Images',
                              style: TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Share photos of the product',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (uploadedMedia.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: uploadedMedia.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              image: DecorationImage(
                                image: NetworkImage(ApiConstants.getFullImageUrl(uploadedMedia[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => uploadedMedia.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (commentController.text.isEmpty) return;
                
                final token = context.read<AppState>().token;
                if (token == null) return;

                try {
                  await ApiService.createReview(token, {
                    'productId': widget.productId,
                    'rating': rating,
                    'comment': commentController.text,
                    'media': uploadedMedia.map((url) => {'type': 'image', 'url': url}).toList(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _fetchReviews();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit review')));
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${_reviews.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _showWriteReviewDialog,
                icon: const Icon(Icons.edit_note, size: 20),
                label: const Text('Write Review'),
                style: TextButton.styleFrom(foregroundColor: AppColors.forestGreen),
              ),
            ],
          ),
        ),
        if (_reviews.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(
                  (_reviews.map((e) => e['rating'] as int).reduce((a, b) => a + b) / _reviews.length).toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text('Average Rating', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.sand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sand.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: AppColors.lightText.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('No reviews yet', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('Be the first to review this product!', style: TextStyle(color: AppColors.lightText, fontSize: 12)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, _) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.forestGreen.withValues(alpha: 0.1),
                        backgroundImage: (review['userId'] != null && review['userId']['profilePicture'] != null) 
                          ? NetworkImage(ApiConstants.getFullImageUrl(review['userId']['profilePicture'])) 
                          : null,
                        child: (review['userId'] == null || review['userId']['profilePicture'] == null) 
                          ? const Icon(Icons.person, size: 18, color: AppColors.forestGreen) 
                          : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review['userId']?['name'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              Icons.star_rounded, 
                              size: 14, 
                              color: i < review['rating'] ? Colors.orange : Colors.grey[300]
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review['comment'] ?? '', style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 14)),
                  if (review['media'] != null && (review['media'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (review['media'] as List).length,
                          itemBuilder: (context, mIdx) {
                            final item = review['media'][mIdx];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: item['type'] == 'image' 
                                  ? DecorationImage(image: NetworkImage(ApiConstants.getFullImageUrl(item['url'])), fit: BoxFit.cover)
                                  : null,
                                color: Colors.black,
                              ),
                              child: item['type'] == 'video' 
                                ? const Icon(Icons.play_circle_fill, color: Colors.white) 
                                : null,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
