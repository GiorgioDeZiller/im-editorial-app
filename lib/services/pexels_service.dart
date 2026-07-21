import 'dart:convert';
import 'package:http/http.dart' as http;

class PexelsService {
  // Cerca immagini verticali (portrait) per un argomento. Ritorna gli URL.
  static Future<List<String>> searchPortrait(
      String apiKey, String query, int count) async {
    final uri = Uri.parse(
        'https://api.pexels.com/v1/search?query=${Uri.encodeQueryComponent(query)}'
        '&per_page=$count&orientation=portrait');
    final res = await http.get(uri, headers: {'Authorization': apiKey});
    if (res.statusCode != 200) {
      throw Exception('Errore Pexels ${res.statusCode}: ${res.body}');
    }
    final photos = jsonDecode(res.body)['photos'] as List? ?? [];
    final urls = <String>[];
    for (final p in photos) {
      final src = p['src'] ?? {};
      final u = (src['portrait'] ?? src['large'] ?? src['original'] ?? '')
          .toString();
      if (u.isNotEmpty) urls.add(u);
    }
    return urls;
  }
}
