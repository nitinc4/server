import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var res = await http.get(Uri.parse('https://zudo-backend.onrender.com/api/products'));
  var json = jsonDecode(res.body);
  for (var p in json) {
    if (p['variants'] != null && (p['variants'] as List).isNotEmpty) {
      print(p['name']);
      print(jsonEncode(p['variants']));
      break;
    }
  }
}
