import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../shared_ui/seller_products_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    
    // Show a premium overlay toast instead of SnackBar which is hidden under modal sheets
    _showToast(context, 'Offer code "$code" copied to clipboard!');
  }

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.forestGreen, AppColors.leafGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Hot Deals & Feed',
          style: GoogleFonts.kalam(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
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
          final feed = state.feedPosts;

          return RefreshIndicator(
            edgeOffset: 0,
            onRefresh: () => state.fetchFeedPosts(),
            color: AppColors.forestGreen,
            child: state.isFeedLoading && feed.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : feed.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 100,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rss_feed_rounded, size: 64, color: AppColors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No seller offers posted yet.',
                                    style: TextStyle(color: AppColors.lightText, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
                          left: 20,
                          right: 20,
                          bottom: 120, // Bottom navigation padding
                        ),
                        itemCount: feed.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          final post = feed[index];
                          return GestureDetector(
                            onTap: () {
                              if (post.sellerId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SellerProductsScreen(
                                      sellerId: post.sellerId,
                                      sellerName: post.sellerName,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color ?? Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                          child: CachedNetworkImage(
                                            imageUrl: post.imageUrl!,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              height: 180,
                                              color: Colors.grey[200],
                                              child: const Center(child: CircularProgressIndicator()),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              height: 180,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image_outlined, size: 40),
                                            ),
                                          ),
                                        ),
                                        if (post.discountPercent != null)
                                          Positioned(
                                            top: 16,
                                            left: 16,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [AppColors.error, Colors.orange],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.error.withValues(alpha: 0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                '${post.discountPercent}% OFF',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                post.sellerName,
                                                style: TextStyle(
                                                  color: AppColors.forestGreen,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${DateTime.now().difference(post.createdAt).inDays}d ago',
                                              style: TextStyle(
                                                color: AppColors.lightText,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          post.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          post.description,
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? AppColors.darkText.withValues(alpha: 0.7),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                        const Divider(height: 32),
                                        Row(
                                          children: [
                                            if (post.offerCode != null && post.offerCode!.isNotEmpty)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _copyToClipboard(context, post.offerCode!),
                                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                                  label: Text(
                                                    'Code: ${post.offerCode}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.forestGreen,
                                                    side: BorderSide(color: AppColors.forestGreen.withValues(alpha: 0.5)),
                                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  ),
                                                ),
                                              )
                                            else
                                              const Spacer(),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  if (post.sellerId.isNotEmpty) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => SellerProductsScreen(
                                                          sellerId: post.sellerId,
                                                          sellerName: post.sellerName,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(Icons.store_rounded, size: 16),
                                                label: const Text(
                                                  'Visit Seller',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.forestGreen,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          );
        },
      ),
    );
  }
}
