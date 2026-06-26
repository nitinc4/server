class ApiConstants {
  static const String baseUrl = 'https://lightgreen-trout-176417.hostingersite.com/api'; // Replace with your IP for physical devices
  static const String uploadsUrl = 'https://lightgreen-trout-176417.hostingersite.com/uploads';

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Replace /api with empty string to get base domain, then join with path
    final base = baseUrl.replaceAll('/api', '');
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }
}
