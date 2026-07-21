import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/heygen_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl   = TextEditingController();
  final _urlCtrl   = TextEditingController();
  final _sbKeyCtrl = TextEditingController();
  final _hgKeyCtrl = TextEditingController();
  bool _obscure    = true;
  bool _obscureSb  = true;
  bool _obscureHg  = true;
  String _model    = 'claude-haiku-4-5-20251001';
  bool _saving     = false;

  // HeyGen
  List<HeyGenAvatar> _avatars = [];
  List<HeyGenVoice> _voices = [];
  String? _avatarId, _avatarType, _avatarName;
  String? _voiceId, _voiceName;
  bool _loadingHg = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _keyCtrl.text   = await StorageService.getApiKey();
    _urlCtrl.text   = await StorageService.getSupabaseUrl();
    _sbKeyCtrl.text = await StorageService.getSupabaseKey();
    _hgKeyCtrl.text = await StorageService.getHeygenKey();
    final m = await StorageService.getModel();
    final av = await StorageService.getHeygenAvatarId();
    final avT = await StorageService.getHeygenAvatarType();
    final avN = await StorageService.getHeygenAvatarName();
    final vo = await StorageService.getHeygenVoiceId();
    final voN = await StorageService.getHeygenVoiceName();
    setState(() {
      _model = m;
      _avatarId = av.isEmpty ? null : av;
      _avatarType = avT.isEmpty ? 'avatar' : avT;
      _avatarName = avN.isEmpty ? null : avN;
      _voiceId = vo.isEmpty ? null : vo;
      _voiceName = voN.isEmpty ? null : voN;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await StorageService.setApiKey(_keyCtrl.text.trim());
    await StorageService.setModel(_model);
    await StorageService.setSupabaseUrl(_urlCtrl.text.trim());
    await StorageService.setSupabaseKey(_sbKeyCtrl.text.trim());
    await StorageService.setHeygenKey(_hgKeyCtrl.text.trim());
    await StorageService.setHeygenAvatarId(_avatarId ?? '');
    await StorageService.setHeygenAvatarType(_avatarType ?? 'avatar');
    await StorageService.setHeygenAvatarName(_avatarName ?? '');
    await StorageService.setHeygenVoiceId(_voiceId ?? '');
    await StorageService.setHeygenVoiceName(_voiceName ?? '');
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Impostazioni salvate'),
          backgroundColor: Color(0xFF22c55e),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _loadHeygenLists() async {
    final key = _hgKeyCtrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inserisci prima la API key di HeyGen'),
          backgroundColor: Color(0xFFf59e0b)));
      return;
    }
    setState(() => _loadingHg = true);
    try {
      final avatars = await HeyGenService.listAvatars(key);
      final voices = await HeyGenService.listVoices(key);
      setState(() {
        _avatars = avatars;
        _voices = voices;
        _loadingHg = false;
        // se la selezione salvata non è più valida, azzerala
        if (_avatarId != null && !_avatars.any((a) => a.id == _avatarId)) {
          _avatarId = null; _avatarName = null;
        }
        if (_voiceId != null && !_voices.any((v) => v.id == _voiceId)) {
          _voiceId = null; _voiceName = null;
        }
      });
    } catch (e) {
      setState(() => _loadingHg = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Errore HeyGen: $e'),
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
        title: const Text('⚙ Impostazioni',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _section('☁  Database Proposte (Supabase)'),
            const SizedBox(height: 8),
            _infoBox(
                'Inserisci le credenziali Supabase per caricare le proposte '
                'automaticamente all\'apertura dell\'app, senza file Excel.'),
            const SizedBox(height: 16),

            _label('Project URL'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _urlCtrl,
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
              decoration: _inputDeco('https://xxxx.supabase.co'),
            ),
            const SizedBox(height: 14),

            _label('Anon Key'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sbKeyCtrl,
              obscureText: _obscureSb,
              style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontFamily: 'monospace',
                  fontSize: 12),
              decoration: _inputDeco('eyJhbGc...').copyWith(
                suffixIcon: _eyeBtn(_obscureSb,
                    () => setState(() => _obscureSb = !_obscureSb)),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Trovi URL e Anon Key in Supabase → Settings → API',
                style: TextStyle(fontSize: 11, color: Color(0xFF666666))),

            const SizedBox(height: 28),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 20),

            _section('🤖  Generazione Testi (Claude API)'),
            const SizedBox(height: 16),

            _label('Anthropic API Key'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _keyCtrl,
              obscureText: _obscure,
              style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontFamily: 'monospace',
                  fontSize: 13),
              decoration: _inputDeco('sk-ant-…').copyWith(
                suffixIcon: _eyeBtn(
                    _obscure, () => setState(() => _obscure = !_obscure)),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
                'Necessaria per generare Newsletter, Script YouTube, Post Social e Short.',
                style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
            const SizedBox(height: 16),

            _label('Modello Claude'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: DropdownButton<String>(
                value: _model,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1A),
                style:
                    const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: const [
                  DropdownMenuItem(
                    value: 'claude-haiku-4-5-20251001',
                    child: Text('Claude Haiku 4.5 — veloce, economico'),
                  ),
                  DropdownMenuItem(
                    value: 'claude-sonnet-4-6',
                    child: Text('Claude Sonnet 4.6 — qualità superiore'),
                  ),
                ],
                onChanged: (v) => setState(() => _model = v!),
              ),
            ),

            const SizedBox(height: 28),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 20),

            // ── HeyGen ──────────────────────────────────────────────
            _section('🎬  Video AI (HeyGen)'),
            const SizedBox(height: 8),
            _infoBox(
                'Serve per generare i video Short con avatar e voce. '
                'Inserisci la API key, poi carica avatar e voci e scegli quelli da usare.'),
            const SizedBox(height: 16),

            _label('HeyGen API Key'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _hgKeyCtrl,
              obscureText: _obscureHg,
              style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontFamily: 'monospace',
                  fontSize: 12),
              decoration: _inputDeco('HeyGen API key').copyWith(
                suffixIcon: _eyeBtn(
                    _obscureHg, () => setState(() => _obscureHg = !_obscureHg)),
              ),
            ),
            const SizedBox(height: 6),
            const Text('La trovi in HeyGen → Settings → API',
                style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _loadingHg
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFF7941D)))
                    : const Icon(Icons.download, size: 16),
                label: Text(_loadingHg
                    ? 'Caricamento…'
                    : 'Carica avatar e voci'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF7941D),
                  side: const BorderSide(color: Color(0xFFF7941D)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _loadingHg ? null : _loadHeygenLists,
              ),
            ),

            if (_avatars.isNotEmpty) ...[
              const SizedBox(height: 16),
              _label('Avatar'),
              const SizedBox(height: 6),
              _dropdown<String>(
                value: _avatarId,
                hint: 'Scegli un avatar',
                items: _avatars
                    .map((a) => DropdownMenuItem(
                        value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: (v) {
                  final a = _avatars.firstWhere((x) => x.id == v);
                  setState(() {
                    _avatarId = a.id;
                    _avatarType = a.type;
                    _avatarName = a.name;
                  });
                },
              ),
            ],
            if (_voices.isNotEmpty) ...[
              const SizedBox(height: 14),
              _label('Voce'),
              const SizedBox(height: 6),
              _dropdown<String>(
                value: _voiceId,
                hint: 'Scegli una voce',
                items: _voices
                    .map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(
                            v.language.isNotEmpty
                                ? '${v.name} · ${v.language}'
                                : v.name,
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  final voice = _voices.firstWhere((x) => x.id == v);
                  setState(() {
                    _voiceId = voice.id;
                    _voiceName = voice.name;
                  });
                },
              ),
            ],
            if (_avatars.isEmpty &&
                (_avatarName != null || _voiceName != null)) ...[
              const SizedBox(height: 12),
              _infoBox(
                  'Selezione attuale — Avatar: ${_avatarName ?? "—"} · '
                  'Voce: ${_voiceName ?? "—"}\n'
                  'Premi "Carica avatar e voci" per cambiarli.'),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7941D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Salva',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF7941D)));

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF999999),
          letterSpacing: 0.5));

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
              left: BorderSide(color: Color(0xFFF7941D), width: 3)),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF999999), height: 1.5)),
      );

  Widget _eyeBtn(bool obscured, VoidCallback onTap) => IconButton(
        icon: Icon(obscured ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF666666)),
        onPressed: onTap,
      );

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
          underline: const SizedBox(),
          items: items,
          onChanged: onChanged,
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF666666)),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFF7941D), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  void dispose() {
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _sbKeyCtrl.dispose();
    _hgKeyCtrl.dispose();
    super.dispose();
  }
}
