import 'dart:convert';
import 'package:http/http.dart' as http;

class MakeService {
  // Invia il video a un webhook Make che lo carica su YouTube (bozza/non in elenco).
  // Ritorna l'URL YouTube se il webhook risponde con { "youtube_url": ... }.
  static Future<String?> publish(
    String webhookUrl, {
    required String videoUrl,
    required String title,
    required String description,
  }) async {
    final res = await http.post(
      Uri.parse(webhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'video_url': videoUrl,
        'title': title,
        'description': description,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Errore Make ${res.statusCode}: ${res.body}');
    }
    // Prova a leggere l'URL YouTube dalla risposta (se il Make lo restituisce)
    try {
      final j = jsonDecode(res.body);
      if (j is Map) {
        final u = (j['youtube_url'] ?? j['url'] ?? j['link'])?.toString();
        if (u != null && u.isNotEmpty) return u;
      }
    } catch (_) {}
    // Se la risposta è un URL semplice
    final body = res.body.trim();
    if (body.startsWith('http')) return body;
    return null;
  }
}
