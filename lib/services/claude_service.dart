import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/proposal.dart';

class ClaudeService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _brand =
      'Innovation Machine è una società di consulenza specializzata in agricoltura, '
      'zootecnia e itticoltura, focalizzata su digitalizzazione, KPI, controllo di '
      'gestione e ottimizzazione operativa.';

  static Future<String> generate({
    required String apiKey,
    required String model,
    required List<Proposal> proposals,
    required String type,
  }) async {
    final prompt = _buildPrompt(type, proposals);

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        // Consente la chiamata diretta dal browser (app web)
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'Errore API ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['content']?[0]?['text'] ?? '';
  }

  static String _topics(List<Proposal> rows) {
    return rows.map((r) =>
      '- [${r.id}] ${r.title}\n'
      '  Problema: ${r.problem}\n'
      '  Settore: ${r.sector}\n'
      '  Angolo video: ${r.angle}\n'
      '  Titolo video: ${r.vidTitle}\n'
      '  Collegamento IM: ${r.imLink}'
    ).join('\n\n');
  }

  static String _buildPrompt(String type, List<Proposal> rows) {
    final topics = _topics(rows);

    switch (type) {
      case 'newsletter':
        return '''Sei un copywriter esperto per $_brand

Argomenti selezionati:
$topics

Scrivi una newsletter professionale per imprenditori agricoli e zootecnici:
- OGGETTO: ... (riga oggetto email, non clickbait)
- Introduzione breve (2-3 righe)
- Sezione per ogni argomento: titolo, paragrafo 80-120 parole, CTA naturale verso il sito
- Chiusura con firma Innovation Machine
- Tono: autorevole ma accessibile
- Lunghezza: 400-600 parole

Scrivi il testo pronto da copiare.''';

      case 'youtube':
        final r = rows.first;
        final extra = rows.length > 1
            ? '\nArgomenti secondari:\n${rows.skip(1).map((x) => '- ${x.title}').join('\n')}'
            : '';
        return '''Sei uno script writer per YouTube. $_brand

Argomento: ${r.title}
Problema: ${r.problem}
Settore: ${r.sector}
Angolo: ${r.angle}
Titolo video: "${r.vidTitle}"
Collegamento IM: ${r.imLink}$extra

Scrivi uno script per un video YouTube di 5-8 minuti:
1. Hook iniziale (30 secondi)
2. Presentazione del problema
3. Corpo con 3-4 punti pratici
4. Esempio concreto
5. Conclusione + CTA naturale verso il sito

Usa [PAUSA] e [ENFASI: testo]. Tono diretto, da esperto.''';

      case 'social':
        return '''Sei un social media manager per $_brand

Argomenti:
$topics

Scrivi UN post LinkedIn e UN post Instagram.

POST LINKEDIN:
- Apri con domanda o dato provocatorio
- Problema + insight (150-200 parole)
- 5-8 hashtag
- CTA verso sito/video

POST INSTAGRAM:
- 80-120 parole
- Emoji misurate
- 10-15 hashtag settoriali

Testi pronti da copiare.''';

      case 'short':
        final r = rows.first;
        final extra = rows.length > 1
            ? '\nAltri spunti (usa solo se davvero pertinenti, ma resta su UNA idea):\n${rows.skip(1).map((x) => '- ${x.title}').join('\n')}'
            : '';
        return '''Sei uno script writer per YouTube Shorts (video verticali) di $_brand

Argomento: ${r.title}
Problema: ${r.problem}
Settore: ${r.sector}
Angolo: ${r.angle}
Collegamento IM: ${r.imLink}$extra

Scrivi il testo per uno SHORT verticale di 30-45 secondi: una persona parla in camera (sarà un avatar AI con voce clonata).

Regole:
- UNA sola idea, chiara e utile
- Hook fortissimo nei primi 2 secondi (una domanda o un dato che ferma lo scroll)
- Linguaggio parlato e naturale, frasi brevi, tono da esperto ma diretto
- 90-130 parole totali (deve stare in ~40 secondi)
- Chiudi con una CTA naturale (seguici / guarda l'approfondimento / contattaci)
- NON usare marcatori tipo [PAUSA], [ENFASI], parentesi o note di regia: verrebbero letti ad alta voce dall'avatar

Produci ESATTAMENTE queste 3 sezioni, con queste intestazioni:

=== COPIONE (incolla questo in HeyGen) ===
(solo il testo che l'avatar deve pronunciare, pulito, senza marcatori)

=== TITOLO A SCHERMO ===
(3-6 parole da mostrare come testo in sovrimpressione all'inizio)

=== DESCRIZIONE + HASHTAG (per l'upload su YouTube) ===
(2-3 righe di descrizione + 4-6 hashtag pertinenti al settore)''';

      default:
        return 'Scrivi un testo divulgativo su:\n$topics';
    }
  }
}
