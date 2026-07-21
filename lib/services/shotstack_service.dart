import 'dart:convert';
import 'package:http/http.dart' as http;

class ShotstackService {
  static String _base(bool sandbox) =>
      sandbox ? 'https://api.shotstack.io/edit/stage'
              : 'https://api.shotstack.io/edit/v1';

  // Monta il video avatar (base) con immagini a tema come stacchi a schermo intero.
  // Ritorna il render id.
  static Future<String> render({
    required String apiKey,
    required bool sandbox,
    required String videoUrl,
    required double duration,
    required List<String> imageUrls,
  }) async {
    final overlays = <Map<String, dynamic>>[];
    final n = imageUrls.length;
    if (n > 0 && duration > 8) {
      const imgLen = 3.0;
      const startWindow = 4.0;         // salta i primi secondi (hook con l'avatar)
      final endWindow = duration - 2.0;
      final span = endWindow - startWindow;
      for (int i = 0; i < n; i++) {
        var t = startWindow + span * (i + 1) / (n + 1) - imgLen / 2;
        if (t < 0) t = 0;
        if (t + imgLen > duration) t = duration - imgLen;
        overlays.add({
          'asset': {'type': 'image', 'src': imageUrls[i]},
          'start': double.parse(t.toStringAsFixed(2)),
          'length': imgLen,
          'fit': 'cover',
          'transition': {'in': 'fade', 'out': 'fade'},
        });
      }
    }

    final body = {
      'timeline': {
        'background': '#000000',
        'tracks': [
          {'clips': overlays}, // track in alto: immagini
          {
            'clips': [
              {
                'asset': {'type': 'video', 'src': videoUrl},
                'start': 0,
                'length': double.parse(duration.toStringAsFixed(2)),
              }
            ]
          }, // track in basso: video avatar (base)
        ],
      },
      'output': {
        'format': 'mp4',
        'size': {'width': 720, 'height': 1280},
      },
    };

    final res = await http.post(
      Uri.parse('${_base(sandbox)}/render'),
      headers: {'x-api-key': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Errore Shotstack ${res.statusCode}: ${res.body}');
    }
    final id = jsonDecode(res.body)['response']?['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Nessun render id: ${res.body}');
    }
    return id;
  }

  // Stato del render. status: queued|fetching|rendering|saving|done|failed
  static Future<Map<String, String?>> status(
      String apiKey, bool sandbox, String id) async {
    final res = await http.get(
      Uri.parse('${_base(sandbox)}/render/$id'),
      headers: {'x-api-key': apiKey},
    );
    if (res.statusCode != 200) {
      throw Exception('Errore stato Shotstack ${res.statusCode}: ${res.body}');
    }
    final r = jsonDecode(res.body)['response'] ?? {};
    return {
      'status': r['status']?.toString(),
      'url': r['url']?.toString(),
      'error': r['error']?.toString(),
    };
  }
}
