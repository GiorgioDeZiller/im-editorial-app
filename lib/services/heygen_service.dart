import 'dart:convert';
import 'package:http/http.dart' as http;

class HeyGenAvatar {
  final String id;
  final String name;
  final String type; // 'avatar' | 'talking_photo'
  HeyGenAvatar(this.id, this.name, this.type);
}

class HeyGenVoice {
  final String id;
  final String name;
  final String language;
  HeyGenVoice(this.id, this.name, this.language);
}

class HeyGenService {
  static const _base = 'https://api.heygen.com';

  static Map<String, String> _headers(String key) => {
        'X-Api-Key': key,
        'Accept': 'application/json',
      };

  // Elenco avatar dell'account (inclusi gli avatar personalizzati/instant)
  static Future<List<HeyGenAvatar>> listAvatars(String key) async {
    final res =
        await http.get(Uri.parse('$_base/v2/avatars'), headers: _headers(key));
    if (res.statusCode != 200) {
      throw Exception('Errore avatar ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body)['data'] ?? {};
    final out = <HeyGenAvatar>[];
    for (final a in (data['avatars'] as List? ?? [])) {
      final id = a['avatar_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      out.add(HeyGenAvatar(
          id, (a['avatar_name'] ?? id).toString(), 'avatar'));
    }
    for (final a in (data['talking_photos'] as List? ?? [])) {
      final id = a['talking_photo_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      out.add(HeyGenAvatar(
          id, (a['talking_photo_name'] ?? 'Foto parlante').toString(),
          'talking_photo'));
    }
    return out;
  }

  // Elenco voci disponibili
  static Future<List<HeyGenVoice>> listVoices(String key) async {
    final res =
        await http.get(Uri.parse('$_base/v2/voices'), headers: _headers(key));
    if (res.statusCode != 200) {
      throw Exception('Errore voci ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body)['data'] ?? {};
    final out = <HeyGenVoice>[];
    for (final v in (data['voices'] as List? ?? [])) {
      final id = v['voice_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      out.add(HeyGenVoice(id, (v['name'] ?? id).toString(),
          (v['language'] ?? '').toString()));
    }
    return out;
  }

  // Avvia la generazione di un video verticale 9:16. Ritorna il video_id.
  static Future<String> generateVideo({
    required String key,
    required String avatarId,
    required String avatarType,
    required String voiceId,
    required String text,
  }) async {
    final character = avatarType == 'talking_photo'
        ? {'type': 'talking_photo', 'talking_photo_id': avatarId}
        : {'type': 'avatar', 'avatar_id': avatarId, 'avatar_style': 'normal'};
    final body = {
      'video_inputs': [
        {
          'character': character,
          'voice': {'type': 'text', 'input_text': text, 'voice_id': voiceId},
        }
      ],
      'dimension': {'width': 720, 'height': 1280}, // verticale 9:16
    };
    final res = await http.post(
      Uri.parse('$_base/v2/video/generate'),
      headers: {..._headers(key), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Errore generazione ${res.statusCode}: ${res.body}');
    }
    final id = jsonDecode(res.body)['data']?['video_id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Nessun video_id nella risposta: ${res.body}');
    }
    return id;
  }

  // Stato del rendering. Ritorna {status, videoUrl}.
  // status: pending | processing | completed | failed
  static Future<Map<String, String?>> videoStatus(
      String key, String videoId) async {
    final res = await http.get(
      Uri.parse('$_base/v1/video_status.get?video_id=$videoId'),
      headers: _headers(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Errore stato ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body)['data'] ?? {};
    return {
      'status': data['status']?.toString(),
      'videoUrl': data['video_url']?.toString(),
      'error': data['error']?.toString(),
    };
  }
}
