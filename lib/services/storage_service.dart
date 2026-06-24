import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyApiKey      = 'im_api_key';
  static const _keyModel       = 'im_model';
  static const _keyLastFile    = 'im_last_file';
  static const _keySupabaseUrl = 'im_supabase_url';
  static const _keySupabaseKey = 'im_supabase_key';

  static Future<String> getApiKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyApiKey) ?? '';
  }

  static Future<void> setApiKey(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyApiKey, v);
  }

  static Future<String> getModel() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyModel) ?? 'claude-haiku-4-5-20251001';
  }

  static Future<void> setModel(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyModel, v);
  }

  static Future<String> getLastFilePath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyLastFile) ?? '';
  }

  static Future<void> setLastFilePath(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyLastFile, v);
  }

  static Future<String> getSupabaseUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySupabaseUrl) ?? '';
  }

  static Future<void> setSupabaseUrl(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySupabaseUrl, v);
  }

  static Future<String> getSupabaseKey() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySupabaseKey) ?? '';
  }

  static Future<void> setSupabaseKey(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySupabaseKey, v);
  }
}
