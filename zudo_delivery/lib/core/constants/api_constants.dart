class ApiConstants {
  static const String baseUrl = 'https://lightgreen-trout-176417.hostingersite.com/api';
  static const String uploadsUrl = 'https://lightgreen-trout-176417.hostingersite.com/uploads';

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = baseUrl.replaceAll('/api', '');
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }
}
