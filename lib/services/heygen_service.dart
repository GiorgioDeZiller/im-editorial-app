import 'dart:convert';
import 'package:http/http.dart' as http;

class HeyGenAvatar {
  final String id;
  final String name;
  final String type;            // mantenuto per compatibilità ('avatar')
  final String? defaultVoiceId;
  HeyGenAvatar(this.id, this.name, this.type, [this.defaultVoiceId]);
}

class HeyGenVoice {
  final String id;
  final String name;
  final String language;
  HeyGenVoice(this.id, this.name, this.language);
}

/// Servizio HeyGen — API v3 (https://api.heygen.com/v3/...)
class HeyGenService {
  static const _base = 'https://api.heygen.com';

  static Map<String, String> _headers(String key) => {
        'X-Api-Key': key,
        'Accept': 'application/json',
      };

  // Elenco avatar personalizzati: espande ogni gruppo nei suoi singoli "look"
  // (es. "Alberto · Felpa arancione", "Alberto · Giacca blu ufficio")
  static Future<List<HeyGenAvatar>> listAvatars(String key) async {
    final res = await http.get(
      Uri.parse('$_base/v3/avatars?ownership=private&limit=50'),
      headers: _headers(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Errore avatar ${res.statusCode}: ${res.body}');
    }
    final groups = jsonDecode(res.body)['data'] as List? ?? [];
    final out = <HeyGenAvatar>[];
    for (final g in groups) {
      final gid = g['id']?.toString() ?? '';
      if (gid.isEmpty) continue;
      final gname = (g['name'] ?? gid).toString();
      final gVoice = g['default_voice_id']?.toString();

      List looks = [];
      try {
        final lr = await http.get(
          Uri.parse('$_base/v3/avatars/looks?group_id=$gid&limit=50'),
          headers: _headers(key),
        );
        if (lr.statusCode == 200) {
          looks = jsonDecode(lr.body)['data'] as List? ?? [];
        }
      } catch (_) {}

      if (looks.isEmpty) {
        // fallback: usa il gruppo come singola opzione
        out.add(HeyGenAvatar(gid, gname, 'avatar', gVoice));
      } else {
        for (final lk in looks) {
          final lid = lk['id']?.toString() ?? '';
          if (lid.isEmpty) continue;
          final lname = (lk['name'] ?? lid).toString();
          out.add(HeyGenAvatar(
            lid,
            '$gname · $lname',
            'avatar',
            lk['default_voice_id']?.toString() ?? gVoice,
          ));
        }
      }
    }
    return out;
  }

  // Elenco voci: prima le private (voci clonate), poi le pubbliche
  static Future<List<HeyGenVoice>> listVoices(String key) async {
    final out = <HeyGenVoice>[];
    Object? lastError;
    for (final type in ['private', 'public']) {
      try {
        final res = await http.get(
          Uri.parse('$_base/v3/voices?type=$type&limit=100'),
          headers: _headers(key),
        );
        if (res.statusCode != 200) {
          lastError = 'Errore voci ${res.statusCode}: ${res.body}';
          continue;
        }
        final list = jsonDecode(res.body)['data'] as List? ?? [];
        for (final v in list) {
          final id = v['voice_id']?.toString() ?? '';
          if (id.isEmpty) continue;
          out.add(HeyGenVoice(id, (v['name'] ?? id).toString(),
              (v['language'] ?? '').toString()));
        }
      } catch (e) {
        lastError = e;
      }
    }
    if (out.isEmpty && lastError != null) {
      throw Exception('$lastError');
    }
    return out;
  }

  // Avvia la generazione di un video verticale 9:16. Ritorna il video_id.
  static Future<String> generateVideo({
    required String key,
    required String avatarId,
    required String avatarType, // non usato in v3, mantenuto per compatibilità
    required String voiceId,
    required String text,
  }) async {
    final body = {
      'type': 'avatar',
      'avatar_id': avatarId,
      'script': text,
      'voice_id': voiceId,
      'aspect_ratio': '9:16', // verticale
      'resolution': '720p',
    };
    final res = await http.post(
      Uri.parse('$_base/v3/videos'),
      headers: {..._headers(key), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Errore generazione ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body)['data'] ?? {};
    final id = data['video_id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Nessun video_id nella risposta: ${res.body}');
    }
    return id;
  }

  // Stato del rendering. Ritorna {status, videoUrl, error}.
  // status v3: pending | processing | completed | failed (create -> waiting)
  static Future<Map<String, String?>> videoStatus(
      String key, String videoId) async {
    final res = await http.get(
      Uri.parse('$_base/v3/videos/$videoId'),
      headers: _headers(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Errore stato ${res.statusCode}: ${res.body}');
    }
    final j = jsonDecode(res.body);
    final data = j['data'] ?? j;
    return {
      'status': data['status']?.toString(),
      'videoUrl': data['video_url']?.toString(),
      'error': data['failure_message']?.toString(),
      'duration': data['duration']?.toString(),
    };
  }
}
