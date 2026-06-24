import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/proposal.dart';
import 'storage_service.dart';

class SupabaseService {
  static String? _url;
  static String? _key;

  static Future<void> init() async {
    _url = await StorageService.getSupabaseUrl();
    _key = await StorageService.getSupabaseKey();
  }

  static bool get isConfigured =>
      _url != null && _url!.isNotEmpty &&
      _key != null && _key!.isNotEmpty;

  static Map<String, String> get _headers => {
    'apikey': _key!,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  static Future<List<Proposal>> fetchProposals() async {
    await init();
    if (!isConfigured) return [];

    final uri = Uri.parse('$_url/rest/v1/proposte?order=data.desc');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode != 200) throw Exception('Errore fetch: ${res.statusCode}');

    final List data = jsonDecode(res.body);
    return data.map((row) => Proposal.fromSupabase(row)).toList();
  }

  static Future<void> updateStatus(String id, String status) async {
    await init();
    if (!isConfigured) return;

    final uri = Uri.parse('$_url/rest/v1/proposte?id=eq.$id');
    await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode({'stato': status}),
    );
  }

  static Future<void> insertProposals(List<Map<String, dynamic>> proposals) async {
    await init();
    if (!isConfigured) return;

    final uri = Uri.parse('$_url/rest/v1/proposte');
    await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(proposals),
    );
  }

  static Future<int> countByStatus(String status) async {
    await init();
    if (!isConfigured) return 0;

    final uri = Uri.parse('$_url/rest/v1/proposte?stato=eq.$status&select=id');
    final res = await http.get(uri, headers: {
      ..._headers,
      'Prefer': 'count=exact',
      'Range-Unit': 'items',
    });
    final countHeader = res.headers['content-range'] ?? '0/0';
    final total = countHeader.split('/').last;
    return int.tryParse(total) ?? 0;
  }
}
