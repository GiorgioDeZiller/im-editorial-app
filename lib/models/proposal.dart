class Proposal {
  final String id;
  final String date;
  final String title;
  final String problem;
  final String sector;
  final String angle;
  final String vidTitle;
  final String siteDeep;
  final String imLink;
  final String sources;
  final int score;
  final String priority;
  String status;
  final String note;

  Proposal({
    required this.id,
    required this.date,
    required this.title,
    required this.problem,
    required this.sector,
    required this.angle,
    required this.vidTitle,
    required this.siteDeep,
    required this.imLink,
    required this.sources,
    required this.score,
    required this.priority,
    required this.status,
    required this.note,
  });

  bool get isNew {
    if (date.isEmpty) return false;
    try {
      final d = DateTime.parse(date);
      return d.isAfter(DateTime.now().subtract(const Duration(days: 15)));
    } catch (_) {
      return false;
    }
  }

  static String _find(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final found = row.keys.firstWhere(
        (rk) => rk.toLowerCase().contains(k.toLowerCase()),
        orElse: () => '',
      );
      if (found.isNotEmpty) return row[found]?.toString().trim() ?? '';
    }
    return '';
  }

  static int _findInt(Map<String, dynamic> row, List<String> keys) {
    final s = _find(row, keys);
    return int.tryParse(s) ?? 0;
  }

  factory Proposal.fromSupabase(Map<String, dynamic> row) {
    return Proposal(
      id:       row['id']?.toString() ?? '',
      date:     row['data']?.toString() ?? '',
      title:    row['titolo']?.toString() ?? '',
      problem:  row['problema']?.toString() ?? '',
      sector:   row['settore']?.toString() ?? '',
      angle:    row['angolo']?.toString() ?? '',
      vidTitle: row['titolo_video']?.toString() ?? '',
      siteDeep: row['approfondimento']?.toString() ?? '',
      imLink:   row['collegamento_im']?.toString() ?? '',
      sources:  row['fonti']?.toString() ?? '',
      score:    (row['punteggio'] as num?)?.toInt() ?? 0,
      priority: row['priorita']?.toString() ?? '',
      status:   row['stato']?.toString() ?? 'Da valutare',
      note:     row['note']?.toString() ?? '',
    );
  }

  factory Proposal.fromRow(Map<String, dynamic> row) {
    return Proposal(
      id:       _find(row, ['ID Proposta', 'ID']),
      date:     _find(row, ['Data Generazione', 'Data']),
      title:    _find(row, ['Titolo dell', 'Titolo']),
      problem:  _find(row, ['Problema Concreto', 'Problema']),
      sector:   _find(row, ['Settore Principale', 'Settore']),
      angle:    _find(row, ['Angolo Editoriale', 'Angolo']),
      vidTitle: _find(row, ['Possibile Titolo Video', 'Titolo Video']),
      siteDeep: _find(row, ['Possibile Approfondimento', 'Approfondimento']),
      imLink:   _find(row, ['Collegamento con i Servizi', 'Collegamento']),
      sources:  _find(row, ['Fonti Attendibili', 'Fonti']),
      score:    _findInt(row, ['Totale su 25', 'Totale']),
      priority: _find(row, ['Priorità Editoriale', 'Priorità']),
      status:   _find(row, ['Stato Decisione', 'Stato']),
      note:     _find(row, ['Nota per la Scelta', 'Nota']),
    );
  }
}
