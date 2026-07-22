import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/proposal.dart';
import '../services/supabase_service.dart';
import '../services/claude_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../widgets/proposal_card.dart';
import 'settings_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Proposal> _all = [];
  List<Proposal> _filtered = [];
  final Set<String> _selected = {};
  final Set<String> _formats = {};   // formati scelti: newsletter/youtube/social
  String _fStatus = '', _fPriority = '', _fSector = '', _search = '';
  bool _loading = false;
  bool _generating = false;
  bool _configured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _autoLoad();
  }

  // ── Carica da Supabase all'avvio ───────────────────────────────────
  Future<void> _autoLoad() async {
    final url = await StorageService.getSupabaseUrl();
    final key = await StorageService.getSupabaseKey();
    if (url.isEmpty || key.isEmpty) {
      setState(() { _configured = false; _loading = false; });
      return;
    }

    setState(() { _loading = true; _error = null; _configured = true; });
    try {
      final proposals = await SupabaseService.fetchProposals();
      final newCount = proposals.where((p) => p.isNew).length;
      setState(() {
        _all = proposals;
        _loading = false;
      });
      _applyFilters();
      if (newCount > 0) await NotificationService.notifyNewProposals(newCount);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ── Aggiorna stato su Supabase ─────────────────────────────────────
  Future<void> _changeStatus(Proposal p, String newStatus) async {
    setState(() => p.status = newStatus);
    _applyFilters();
    try {
      await SupabaseService.updateStatus(p.id, newStatus);
    } catch (_) {}
  }

  // ── Filtri ─────────────────────────────────────────────────────────
  void _applyFilters() {
    setState(() {
      _filtered = _all.where((p) {
        if (_fStatus.isNotEmpty && p.status != _fStatus) return false;
        if (_fPriority.isNotEmpty && p.priority != _fPriority) return false;
        if (_fSector.isNotEmpty && !p.sector.contains(_fSector)) return false;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          return p.title.toLowerCase().contains(q) ||
              p.problem.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q);
        }
        return true;
      }).toList();
    });
  }

  // ── Genera contenuto con Claude (tutti i formati scelti) ───────────
  Future<void> _generateSelected() async {
    final apiKey = await StorageService.getApiKey();
    if (apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Imposta la API key nelle impostazioni'),
              backgroundColor: Color(0xFFf59e0b)));
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()));
      }
      return;
    }

    final selected = _all.where((p) => _selected.contains(p.id)).toList();
    if (selected.isEmpty || _formats.isEmpty) return;

    final model = await StorageService.getModel();
    final titles = {
      'newsletter': '📧 Newsletter',
      'youtube': '▶ Script YouTube',
      'social': '📱 Post Social',
      'short': '🎬 Short verticale'
    };
    // ordine fisso a prescindere dall'ordine di selezione
    final order = ['newsletter', 'youtube', 'social', 'short']
        .where(_formats.contains)
        .toList();

    setState(() => _generating = true);
    try {
      final buffer = StringBuffer();
      for (final type in order) {
        final text = await ClaudeService.generate(
            apiKey: apiKey, model: model, proposals: selected, type: type);
        if (buffer.isNotEmpty) buffer.write('\n\n\n');
        if (order.length > 1) {
          buffer.write(
              '═══════════════════════\n${titles[type]}\n═══════════════════════\n\n');
        }
        buffer.write(text);
        await NotificationService.notifyGenerated(type);
      }
      if (mounted) {
        setState(() => _generating = false);
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ResultScreen(
                    title: order.length > 1
                        ? 'Contenuti generati'
                        : (titles[order.first] ?? 'Risultato'),
                    text: buffer.toString(),
                    proposalId:
                        selected.length == 1 ? selected.first.id : null)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: const Color(0xFFef4444)));
      }
    }
  }

  // ── Stats ──────────────────────────────────────────────────────────
  int get _newCount => _all.where((p) => p.isNew).length;
  int get _approvedCount => _all.where((p) => p.status == 'Approvato').length;
  int get _pendingCount => _all.where((p) => p.status == 'Da valutare').length;
  int get _rejectedCount => _all.where((p) => p.status == 'Scartato').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _all.isNotEmpty ? _buildActionBar() : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF7941D), Color(0xFFD4750A)]),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('IM',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editorial Manager',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF))),
              Text('Innovation Machine',
                  style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
            ],
          ),
          if (_newCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('🆕 $_newCount',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFFF7941D)),
          tooltip: 'Aggiorna proposte',
          onPressed: _autoLoad,
        ),
        Consumer<ThemeService>(
          builder: (_, ts, __) => IconButton(
            icon: Icon(ts.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: ts.isDark ? 'Tema chiaro' : 'Tema scuro',
            onPressed: ts.toggle,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Impostazioni',
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
            _autoLoad();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: Color(0xFFF7941D)),
          SizedBox(height: 16),
          Text('Caricamento proposte…',
              style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Errore di connessione',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF))),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF999999)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7941D),
                  foregroundColor: Colors.white),
              onPressed: _autoLoad,
            ),
          ]),
        ),
      );
    }

    if (!_configured) return _buildSetupScreen();
    if (_all.isEmpty) return _buildEmptyConnected();

    return Column(children: [
      _buildFilters(),
      _buildStats(),
      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildEmptyConnected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_done, size: 64, color: Color(0xFFF7941D)),
          const SizedBox(height: 16),
          const Text('Database connesso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: Color(0xFFFFFFFF))),
          const SizedBox(height: 8),
          const Text('Nessuna proposta ancora presente.\nL\'agente le aggiungerà automaticamente ogni 15 giorni.',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999), height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Aggiorna'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7941D),
                foregroundColor: Colors.white),
            onPressed: _autoLoad,
          ),
        ]),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF7941D), width: 2),
              ),
              child: const Icon(Icons.cloud_off,
                  size: 40, color: Color(0xFFF7941D)),
            ),
            const SizedBox(height: 24),
            const Text('Connetti il database',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFFFFF))),
            const SizedBox(height: 12),
            const Text(
              'Configura le credenziali Supabase nelle impostazioni.\n'
              'Le proposte si caricheranno automaticamente ad ogni apertura.',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF999999), height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Apri Impostazioni',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7941D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                  _autoLoad();
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                    left: BorderSide(color: Color(0xFFF7941D), width: 3)),
              ),
              child: const Text(
                '☁  Le proposte vengono aggiornate automaticamente ogni 15 giorni '
                'dall\'agente IM Editorial.\nTi arriverà una notifica email quando '
                'sono pronte.',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF999999), height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: [
              _filterGroup(
                  'Priorità', ['', 'Alta', 'Media', 'Bassa'], _fPriority,
                  (v) {
                setState(() => _fPriority = v);
                _applyFilters();
              }),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: TextField(
              style: const TextStyle(
                  color: Color(0xFFFFFFFF), fontSize: 13),
              decoration: InputDecoration(
                hintText: '🔍 Cerca titolo o problema…',
                hintStyle:
                    const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                isDense: true,
              ),
              onChanged: (v) {
                setState(() => _search = v.trim());
                _applyFilters();
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
        ],
      ),
    );
  }

  Widget _filterGroup(String label, List<String> opts, String current,
      ValueChanged<String> onTap) {
    final labels = {
      '': 'Tutti',
      'Da valutare': 'Da valutare',
      'Approvato': 'Approvato',
      'Scartato': 'Scartato',
      'Alta': 'Alta',
      'Media': 'Media',
      'Bassa': 'Bassa'
    };
    return Row(
      children: opts.map((opt) {
        final active = current == opt;
        return GestureDetector(
          onTap: () => onTap(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFF7941D)
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: active
                      ? const Color(0xFFF7941D)
                      : const Color(0xFF2A2A2A)),
            ),
            child: Text(labels[opt] ?? opt,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: active
                        ? Colors.white
                        : const Color(0xFF999999))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStats() {
    // (conteggio, etichetta, colore, valore-stato per il filtro)
    final chips = [
      ('${_all.length}', 'Totale', const Color(0xFF999999), ''),
      ('$_pendingCount', 'Da valutare', const Color(0xFFf59e0b), 'Da valutare'),
      ('$_approvedCount', 'Approvate', const Color(0xFF22c55e), 'Approvato'),
      ('$_rejectedCount', 'Scartate', const Color(0xFFef4444), 'Scartato'),
    ];
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: chips.map((c) {
          final active = _fStatus == c.$4;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _fStatus = c.$4);
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? c.$3.withValues(alpha: 0.15)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: active ? c.$3 : const Color(0xFF2A2A2A),
                      width: active ? 1.5 : 1),
                ),
                child: Column(children: [
                  Text(c.$1,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.$3)),
                  Text(c.$2,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.normal,
                          color: active ? c.$3 : const Color(0xFF666666))),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🔍', style: TextStyle(fontSize: 48)),
          SizedBox(height: 8),
          Text('Nessun risultato',
              style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = _filtered[i];
        return ProposalCard(
          proposal: p,
          isSelected: _selected.contains(p.id),
          onTap: () => setState(() {
            _selected.contains(p.id)
                ? _selected.remove(p.id)
                : _selected.add(p.id);
          }),
          onStatusChange: (s) => _changeStatus(p, s),
          onEditField: (column, value) =>
              SupabaseService.updateFields(p.id, {column: value}),
        );
      },
    );
  }

  Widget _buildActionBar() {
    final n = _selected.length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (n > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Text(
                      n > 1 ? '$n proposte selezionate' : '$n proposta selezionata',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selected.clear()),
                    child: const Text('✕ Deseleziona',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                  ),
                ]),
              ),
            if (_generating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF7941D))),
                      SizedBox(width: 10),
                      Text('Generazione in corso…',
                          style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 13)),
                    ]),
              )
            else ...[
              Row(children: [
                Expanded(child: _formatBtn('📧', 'Newsletter', 'newsletter')),
                const SizedBox(width: 6),
                Expanded(child: _formatBtn('▶', 'YouTube', 'youtube')),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _formatBtn('📱', 'Social', 'social')),
                const SizedBox(width: 6),
                Expanded(child: _formatBtn('🎬', 'Short YT', 'short')),
              ]),
              const SizedBox(height: 8),
              _generaBtn(n > 0 && _formats.isNotEmpty),
            ],
          ],
        ),
      ),
    );
  }

  // Riquadro formato selezionabile: bordo arancione marcato quando attivo
  Widget _formatBtn(String icon, String label, String type) {
    final active = _formats.contains(type);
    return GestureDetector(
      onTap: () => setState(() {
        active ? _formats.remove(type) : _formats.add(type);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A1E0B) : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? const Color(0xFFF7941D) : const Color(0xFF2A2A2A),
              width: active ? 2.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text('$icon $label',
            style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                color: active
                    ? const Color(0xFFFFB347)
                    : const Color(0xFF888888))),
      ),
    );
  }

  Widget _generaBtn(bool enabled) {
    return GestureDetector(
      onTap: enabled ? _generateSelected : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF7941D) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
            enabled
                ? '⚡ Genera (${_formats.length})'
                : (_selected.isEmpty
                    ? 'Seleziona almeno una proposta'
                    : 'Scegli un formato'),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: enabled ? Colors.black : const Color(0xFF666666))),
      ),
    );
  }
}
