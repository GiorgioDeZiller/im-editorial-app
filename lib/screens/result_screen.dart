import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/heygen_service.dart';
import '../services/pexels_service.dart';
import '../services/shotstack_service.dart';
import 'settings_screen.dart';

class ResultScreen extends StatefulWidget {
  final String title;
  final String text;

  const ResultScreen({super.key, required this.title, required this.text});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final TextEditingController _ctrl;
  bool _copied = false;

  // Video (HeyGen)
  late final bool _hasShort;
  bool _videoBusy = false;
  String? _videoMsg;
  String? _videoUrl;
  double _videoDuration = 40;

  // B-roll (Pexels + Shotstack)
  bool _brollBusy = false;
  String? _brollMsg;
  String? _brollUrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.text);
    _hasShort = widget.text.contains('=== COPIONE');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _ctrl.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  // Estrae il testo tra "=== COPIONE ..." e il marcatore successivo "==="
  String? _extractCopione() {
    final t = _ctrl.text;
    final idx = t.indexOf('=== COPIONE');
    if (idx < 0) return null;
    final nl = t.indexOf('\n', idx);
    if (nl < 0) return null;
    final rest = t.substring(nl + 1);
    final next = rest.indexOf('===');
    final body = next >= 0 ? rest.substring(0, next) : rest;
    final result = body.trim();
    return result.isEmpty ? null : result;
  }

  Future<void> _generateVideo() async {
    final copione = _extractCopione();
    if (copione == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nessun copione trovato: genera prima uno Short'),
          backgroundColor: Color(0xFFf59e0b)));
      return;
    }
    final key = await StorageService.getHeygenKey();
    final avatarId = await StorageService.getHeygenAvatarId();
    final avatarType = await StorageService.getHeygenAvatarType();
    final voiceId = await StorageService.getHeygenVoiceId();

    if (key.isEmpty || avatarId.isEmpty || voiceId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Configura HeyGen nelle impostazioni (API key + avatar + voce)'),
          backgroundColor: Color(0xFFf59e0b)));
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }

    setState(() {
      _videoBusy = true;
      _videoUrl = null;
      _videoMsg = 'Avvio generazione…';
    });
    try {
      final videoId = await HeyGenService.generateVideo(
        key: key,
        avatarId: avatarId,
        avatarType: avatarType.isEmpty ? 'avatar' : avatarType,
        voiceId: voiceId,
        text: copione,
      );
      if (mounted) {
        setState(() =>
            _videoMsg = 'In rendering… (può richiedere 1-2 minuti)');
      }
      // polling: 45 tentativi x 8s ≈ 6 minuti
      for (int i = 0; i < 45; i++) {
        await Future.delayed(const Duration(seconds: 8));
        if (!mounted) return;
        final st = await HeyGenService.videoStatus(key, videoId);
        final status = st['status'];
        if (status == 'completed') {
          setState(() {
            _videoBusy = false;
            _videoUrl = st['videoUrl'];
            _videoDuration = double.tryParse(st['duration'] ?? '') ?? 40;
            _videoMsg = null;
          });
          return;
        }
        if (status == 'failed') {
          throw Exception(st['error'] ?? 'rendering fallito');
        }
        setState(() => _videoMsg = 'In rendering… ${(i + 1) * 8}s');
      }
      throw Exception('timeout: il video non è pronto dopo alcuni minuti');
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoBusy = false;
          _videoMsg = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Errore video: $e'),
            backgroundColor: const Color(0xFFef4444)));
      }
    }
  }

  // Estrae le parole chiave immagini dalla sezione "=== IMMAGINI ..."
  String? _extractKeywords() {
    final t = _ctrl.text;
    final idx = t.indexOf('=== IMMAGINI');
    if (idx < 0) return null;
    final nl = t.indexOf('\n', idx);
    if (nl < 0) return null;
    final rest = t.substring(nl + 1);
    final next = rest.indexOf('===');
    final body = (next >= 0 ? rest.substring(0, next) : rest).trim();
    return body.isEmpty ? null : body;
  }

  Future<void> _generateBroll() async {
    if (_videoUrl == null) return;
    final pexelsKey = await StorageService.getPexelsKey();
    final ssKey = await StorageService.getShotstackKey();
    final sandbox = await StorageService.getShotstackSandbox();
    if (pexelsKey.isEmpty || ssKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Configura Pexels e Shotstack nelle impostazioni (sezione Montaggio b-roll)'),
          backgroundColor: Color(0xFFf59e0b)));
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }

    // query: parole chiave dal testo, oppure fallback sul titolo
    final query = _extractKeywords() ?? widget.title;
    final nImages = (_videoDuration / 10).round().clamp(2, 4);

    setState(() {
      _brollBusy = true;
      _brollUrl = null;
      _brollMsg = 'Cerco immagini a tema…';
    });
    try {
      final images =
          await PexelsService.searchPortrait(pexelsKey, query, nImages);
      if (images.isEmpty) {
        throw Exception('nessuna immagine trovata per: $query');
      }
      setState(() => _brollMsg = 'Monto il video (${images.length} immagini)…');
      final renderId = await ShotstackService.render(
        apiKey: ssKey,
        sandbox: sandbox,
        videoUrl: _videoUrl!,
        duration: _videoDuration,
        imageUrls: images,
      );
      for (int i = 0; i < 45; i++) {
        await Future.delayed(const Duration(seconds: 8));
        if (!mounted) return;
        final st = await ShotstackService.status(ssKey, sandbox, renderId);
        final status = st['status'];
        if (status == 'done') {
          setState(() {
            _brollBusy = false;
            _brollUrl = st['url'];
            _brollMsg = null;
          });
          return;
        }
        if (status == 'failed') {
          throw Exception(st['error'] ?? 'montaggio fallito');
        }
        setState(() => _brollMsg = 'Montaggio in corso… ${(i + 1) * 8}s');
      }
      throw Exception('timeout montaggio');
    } catch (e) {
      if (mounted) {
        setState(() {
          _brollBusy = false;
          _brollMsg = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Errore b-roll: $e'),
            backgroundColor: const Color(0xFFef4444)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFFFFFFF),
        title: Text(widget.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_copied ? Icons.check : Icons.copy,
                color: const Color(0xFFFFFFFF)),
            tooltip: 'Copia',
            onPressed: _copy,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFFFFFFF)),
            tooltip: 'Condividi',
            onPressed: () => Share.share(_ctrl.text, subject: widget.title),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _ctrl,
          maxLines: null,
          expands: true,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFFFFFFFF), height: 1.7),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFF7941D), width: 2)),
            contentPadding: const EdgeInsets.all(16),
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasShort) ...[
                _videoSection(),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                      label: Text(_copied ? 'Copiato!' : 'Copia tutto'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFFFFF),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _copy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Condividi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7941D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () =>
                          Share.share(_ctrl.text, subject: widget.title),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoSection() {
    // Video pronto
    if (_videoUrl != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0f2a1a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF22c55e)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.check_circle, color: Color(0xFF22c55e), size: 18),
              SizedBox(width: 6),
              Text('Video pronto',
                  style: TextStyle(
                      color: Color(0xFF22c55e),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            SelectableText(_videoUrl!,
                style: const TextStyle(
                    color: Color(0xFF86efac), fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Copia link'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF86efac),
                    side: const BorderSide(color: Color(0xFF22c55e)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _videoUrl!));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Link copiato'),
                              backgroundColor: Color(0xFF22c55e)));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text('Apri / Condividi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22c55e),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => Share.share(_videoUrl!,
                      subject: 'Video Short — ${widget.title}'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF14532d), height: 1),
            const SizedBox(height: 10),
            _brollInline(),
          ],
        ),
      );
    }

    // Generazione in corso
    if (_videoBusy) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF7941D)),
        ),
        child: Row(children: [
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFF7941D))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_videoMsg ?? 'Generazione video…',
                style: const TextStyle(
                    color: Color(0xFFFFB347), fontSize: 12)),
          ),
        ]),
      );
    }

    // Pulsante iniziale
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Text('🎬', style: TextStyle(fontSize: 16)),
        label: const Text('Genera video (HeyGen)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: const Color(0xFFFFB347),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFF7941D))),
        ),
        onPressed: _generateVideo,
      ),
    );
  }

  // Sezione b-roll (compare sotto al video HeyGen pronto)
  Widget _brollInline() {
    if (_brollUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎞️ Video con b-roll pronto',
              style: TextStyle(
                  color: Color(0xFF86efac),
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const SizedBox(height: 6),
          SelectableText(_brollUrl!,
              style: const TextStyle(color: Color(0xFF86efac), fontSize: 11)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copia link'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF86efac),
                    side: const BorderSide(color: Color(0xFF22c55e)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _brollUrl!));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Link copiato'),
                        backgroundColor: Color(0xFF22c55e)));
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('Apri / Condividi'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22c55e),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () => Share.share(_brollUrl!,
                    subject: 'Short b-roll — ${widget.title}'),
              ),
            ),
          ]),
        ],
      );
    }
    if (_brollBusy) {
      return Row(children: [
        const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFF7941D))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_brollMsg ?? 'Montaggio…',
              style: const TextStyle(color: Color(0xFFFFB347), fontSize: 12)),
        ),
      ]);
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Text('🎞️', style: TextStyle(fontSize: 14)),
        label: const Text('Aggiungi immagini a tema (b-roll)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFB347),
            side: const BorderSide(color: Color(0xFFF7941D)),
            padding: const EdgeInsets.symmetric(vertical: 11)),
        onPressed: _generateBroll,
      ),
    );
  }
}
