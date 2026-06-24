import 'package:flutter/material.dart';
import '../models/proposal.dart';

class ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChange;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.isSelected,
    required this.onTap,
    required this.onStatusChange,
  });

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
    final theme = Theme.of(context);
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
      onTap: onTap,
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
              ? [BoxShadow(color: const Color(0xFFF7941D).withOpacity(0.3), blurRadius: 12)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(proposal.id,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11, color: Color(0xFF666666))),
                  Row(
                    children: [
                      if (proposal.isNew)
                        _badge('NUOVO', const Color(0xFFfef3c7), const Color(0xFF92400e)),
                      const SizedBox(width: 4),
                      if (proposal.priority.isNotEmpty)
                        _badge(proposal.priority, _priorityBg(), _priorityColor(context)),
                      const SizedBox(width: 4),
                      _badge(proposal.status, _statusBg(), _statusColor()),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(proposal.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF),
                      height: 1.35)),

              const SizedBox(height: 6),

              // Problem
              Text(proposal.problem,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.5)),

              if (proposal.vidTitle.isNotEmpty) ...[
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
                      onTap: () => onStatusChange('Approvato'),
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
                      onTap: () => onStatusChange('Scartato'),
                    ),
                  ),
                  if (proposal.status != 'Da valutare') ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onStatusChange('Da valutare'),
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
                    Icon(Icons.check_circle, color: const Color(0xFFF7941D), size: 14),
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
