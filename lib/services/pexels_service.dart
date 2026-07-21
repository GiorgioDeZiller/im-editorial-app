import 'dart:convert';
import 'package:http/http.dart' as http;

class PexelsService {
  // Sceglie le immagini migliori: una ricerca per ciascuna parola chiave,
  // prendendo le prime (più rilevanti/popolari) e alternandole per varietà.
  static Future<List<String>> searchBest(
      String apiKey, List<String> keywords, int count) async {
    final pools = <List<String>>[];
    for (final kw in keywords) {
      final q = kw.trim();
      if (q.isEmpty) continue;
      try {
        final urls = await searchPortrait(apiKey, q, 6); // top 6 per keyword
        if (urls.isNotEmpty) pools.add(urls);
      } catch (_) {}
    }
    if (pools.isEmpty) return [];
    // round-robin: prima la #1 di ogni keyword, poi la #2, ecc.
    final out = <String>[];
    for (int depth = 0; depth < 6 && out.length < count; depth++) {
      for (final pool in pools) {
        if (depth < pool.length && out.length < count) {
          final u = pool[depth];
          if (!out.contains(u)) out.add(u);
        }
      }
    }
    return out;
  }

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
