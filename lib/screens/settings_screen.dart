import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl   = TextEditingController();
  final _urlCtrl   = TextEditingController();
  final _sbKeyCtrl = TextEditingController();
  bool _obscure    = true;
  bool _obscureSb  = true;
  String _model    = 'claude-haiku-4-5-20251001';
  bool _saving     = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _keyCtrl.text   = await StorageService.getApiKey();
    _urlCtrl.text   = await StorageService.getSupabaseUrl();
    _sbKeyCtrl.text = await StorageService.getSupabaseKey();
    final m = await StorageService.getModel();
    setState(() => _model = m);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await StorageService.setApiKey(_keyCtrl.text.trim());
    await StorageService.setModel(_model);
    await StorageService.setSupabaseUrl(_urlCtrl.text.trim());
    await StorageService.setSupabaseKey(_sbKeyCtrl.text.trim());
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                    left: BorderSide(color: Color(0xFFF7941D), width: 3)),
              ),
              child: const Text(
                'Inserisci le credenziali Supabase per caricare le proposte '
                'automaticamente all\'apertura dell\'app, senza file Excel.',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF999999), height: 1.5),
              ),
            ),
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSb ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF666666),
                  ),
                  onPressed: () =>
                      setState(() => _obscureSb = !_obscureSb),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Trovi URL e Anon Key in Supabase → Settings → API',
              style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),

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
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF666666),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Necessaria per generare Newsletter, Script YouTube e Post Social.',
              style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),
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
                style: const TextStyle(
                    color: Color(0xFFFFFFFF), fontSize: 13),
                underline: const SizedBox(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
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

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7941D),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text('Salva',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF7941D)),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF999999),
            letterSpacing: 0.5),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF666666)),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Color(0xFFF7941D), width: 2)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      );

  @override
  void dispose() {
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _sbKeyCtrl.dispose();
    super.dispose();
  }
}
