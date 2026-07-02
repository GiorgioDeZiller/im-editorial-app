import 'package:flutter/material.dart';
import '../models/proposal.dart';

class ProposalCard extends StatefulWidget {
  final Proposal proposal;
  final bool isSelected;
  final VoidCallback onTap;              // attiva/disattiva la selezione
  final ValueChanged<String> onStatusChange;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.isSelected,
    required this.onTap,
    required this.onStatusChange,
  });

  @override
  State<ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<ProposalCard> {
  bool _expanded = false;

  Proposal get proposal => widget.proposal;
  bool get isSelected => widget.isSelected;

  Color _priorityColor(BuildContext ctx) {
    switch (proposal.priority) {
      case 'Alta':   return const Color(0xFF22c55e);
      case 'Media':  return const Color(0xFFf59e0b);
      default:       return const Color(0xFFef4444);
    }
  }

  Color _statusColor() {
    switch (proposal.status) {
      case 'Approvato': return const Color(0xFF22c55e);
      case 'Scartato':  return const Color(0xFFef4444);
      default:          return const Color(0xFFf59e0b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? const Color(0xFF1F1F1F)
        : proposal.status == 'Approvato'
            ? const Color(0xFF0f2a1a)
            : proposal.status == 'Scartato'
                ? const Color(0xFF2a0f0f)
                : const Color(0xFF1A1A1A);

    final borderColor = isSelected
        ? const Color(0xFFF7941D)
        : proposal.isNew
            ? const Color(0xFFf59e0b)
            : proposal.status == 'Approvato'
                ? const Color(0xFF22c55e)
                : proposal.status == 'Scartato'
                    ? const Color(0xFFef4444)
                    : const Color(0xFF2A2A2A);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFF7941D).withValues(alpha: 0.3), blurRadius: 12)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  // Casella di selezione (per generare contenuto)
                  _selectBox(),
                  const SizedBox(width: 8),
                  Text(proposal.id,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11, color: Color(0xFF666666))),
                  const Spacer(),
                  if (proposal.isNew)
                    _badge('NUOVO', const Color(0xFFfef3c7), const Color(0xFF92400e)),
                  if (proposal.priority.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _badge(proposal.priority, _priorityBg(), _priorityColor(context)),
                  ],
                  const SizedBox(width: 4),
                  _badge(proposal.status, _statusBg(), _statusColor()),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: const Color(0xFF888888)),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(proposal.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF),
                      height: 1.35)),

              const SizedBox(height: 6),

              // Problem (troncato se chiuso, completo se aperto)
              Text(proposal.problem,
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.5)),

              // Riga titolo video (solo in modalità compatta)
              if (!_expanded && proposal.vidTitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(width: 2, height: 30, color: const Color(0xFFF7941D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('▶ ${proposal.vidTitle}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF666666))),
                    ),
                  ],
                ),
              ],

              // Pannello dettagli completo (quando espanso)
              if (_expanded) _buildDetails(),

              const SizedBox(height: 8),

              // Score bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: proposal.score / 25,
                  minHeight: 3,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF7941D)),
                ),
              ),

              const SizedBox(height: 6),

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Punteggio: ${proposal.score}/25',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  Text(proposal.date,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              const SizedBox(height: 8),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      label: '✓ Approva',
                      active: proposal.status == 'Approvato',
                      activeColor: const Color(0xFF22c55e),
                      activeBg: const Color(0xFF14532d),
                      inactiveBg: const Color(0xFF1a3a2a),
                      inactiveColor: const Color(0xFF86efac),
                      onTap: () => widget.onStatusChange('Approvato'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _actionBtn(
                      label: '✕ Scarta',
                      active: proposal.status == 'Scartato',
                      activeColor: Colors.white,
                      activeBg: const Color(0xFFef4444),
                      inactiveBg: const Color(0xFF3a1a1a),
                      inactiveColor: const Color(0xFFfca5a5),
                      onTap: () => widget.onStatusChange('Scartato'),
                    ),
                  ),
                  if (proposal.status != 'Da valutare') ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => widget.onStatusChange('Da valutare'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('↺',
                            style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                      ),
                    ),
                  ],
                ],
              ),

              // Selection indicator
              if (isSelected) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFFF7941D), size: 14),
                    const SizedBox(width: 4),
                    const Text('Selezionata per generare contenuto',
                        style: TextStyle(fontSize: 11, color: Color(0xFFF7941D))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Casella di selezione ─────────────────────────────────────────────
  Widget _selectBox() {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7941D) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isSelected ? const Color(0xFFF7941D) : const Color(0xFF555555),
              width: 1.5),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 15, color: Colors.black)
            : null,
      ),
    );
  }

  // ── Pannello dettagli ────────────────────────────────────────────────
  Widget _buildDetails() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detail('Settore principale', proposal.sector),
          _detail('Angolo editoriale (YouTube)', proposal.angle),
          _detail('Possibile titolo video', proposal.vidTitle),
          _detail('Possibile approfondimento sul sito', proposal.siteDeep),
          _detail('Collegamento con i servizi IM', proposal.imLink),
          _detail('Fonti attendibili e aggiornate', proposal.sources),
          _detail('Priorità editoriale', proposal.priority),
          _detail('Punteggio totale', '${proposal.score}/25'),
          _detail('Nota per la scelta finale', proposal.note),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF7941D),
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFFDDDDDD), height: 1.45)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg,
              letterSpacing: 0.3)),
    );
  }

  Widget _actionBtn({
    required String label,
    required bool active,
    required Color activeColor,
    required Color activeBg,
    required Color inactiveBg,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? activeColor : inactiveColor)),
      ),
    );
  }

  Color _priorityBg() {
    switch (proposal.priority) {
      case 'Alta':  return const Color(0xFFdcfce7);
      case 'Media': return const Color(0xFFfef9c3);
      default:      return const Color(0xFFfee2e2);
    }
  }

  Color _statusBg() {
    switch (proposal.status) {
      case 'Approvato': return const Color(0xFFdcfce7);
      case 'Scartato':  return const Color(0xFFfee2e2);
      default:          return const Color(0xFFfef9c3);
    }
  }
}
