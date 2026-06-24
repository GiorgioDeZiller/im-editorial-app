import 'dart:io';
import 'package:excel/excel.dart';
import '../models/proposal.dart';

class ExcelService {
  static List<Proposal> parse(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    Sheet? sheet;
    for (final name in excel.tables.keys) {
      if (name.toLowerCase().contains('proposte') || sheet == null) {
        sheet = excel.tables[name];
      }
    }
    if (sheet == null) return [];

    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    // Build header map: column name → index
    final header = <String, int>{};
    for (var i = 0; i < rows[0].length; i++) {
      final v = rows[0][i]?.value?.toString().trim() ?? '';
      if (v.isNotEmpty) header[v] = i;
    }

    final proposals = <Proposal>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final map = <String, dynamic>{};
      header.forEach((col, idx) {
        map[col] = idx < row.length ? row[idx]?.value?.toString().trim() ?? '' : '';
      });
      final p = Proposal.fromRow(map);
      if (p.id.isNotEmpty) proposals.add(p);
    }
    return proposals;
  }

  static void updateStatuses(String filePath, Map<String, String> statusMap) {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    Sheet? sheet;
    String? sheetName;
    for (final name in excel.tables.keys) {
      if (name.toLowerCase().contains('proposte') || sheet == null) {
        sheet = excel.tables[name];
        sheetName = name;
      }
    }
    if (sheet == null || sheetName == null) return;

    final rows = sheet.rows;
    if (rows.isEmpty) return;

    // Find column indices
    int idCol = -1, statusCol = -1;
    for (var i = 0; i < rows[0].length; i++) {
      final v = rows[0][i]?.value?.toString().toLowerCase() ?? '';
      if (v.contains('id proposta') || v == 'id') idCol = i;
      if (v.contains('stato decisione')) statusCol = i;
    }
    if (idCol < 0 || statusCol < 0) return;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final id = idCol < row.length ? row[idCol]?.value?.toString() ?? '' : '';
      if (statusMap.containsKey(id)) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: statusCol, rowIndex: r),
          TextCellValue(statusMap[id]!),
        );
      }
    }

    final encoded = excel.encode();
    if (encoded != null) {
      File(filePath).writeAsBytesSync(encoded);
    }
  }
}
