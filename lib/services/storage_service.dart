import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyApiKey      = 'im_api_key';
  static const _keyModel       = 'im_model';
  static const _keyLastFile    = 'im_last_file';
  static const _keySupabaseUrl = 'im_supabase_url';
  static const _keySupabaseKey = 'im_supabase_key';
  static const _keyHgKey        = 'im_heygen_key';
  static const _keyHgAvatarId   = 'im_heygen_avatar_id';
  static const _keyHgAvatarType = 'im_heygen_avatar_type';
  static const _keyHgAvatarName = 'im_heygen_avatar_name';
  static const _keyHgVoiceId    = 'im_heygen_voice_id';
  static const _keyHgVoiceName  = 'im_heygen_voice_name';

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

  // ── HeyGen (generazione video) ─────────────────────────────────────
  static Future<String> _get(String k) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(k) ?? '';
  }

  static Future<void> _set(String k, String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(k, v);
  }

  static Future<String> getHeygenKey() => _get(_keyHgKey);
  static Future<void> setHeygenKey(String v) => _set(_keyHgKey, v);
  static Future<String> getHeygenAvatarId() => _get(_keyHgAvatarId);
  static Future<void> setHeygenAvatarId(String v) => _set(_keyHgAvatarId, v);
  static Future<String> getHeygenAvatarType() => _get(_keyHgAvatarType);
  static Future<void> setHeygenAvatarType(String v) => _set(_keyHgAvatarType, v);
  static Future<String> getHeygenAvatarName() => _get(_keyHgAvatarName);
  static Future<void> setHeygenAvatarName(String v) => _set(_keyHgAvatarName, v);
  static Future<String> getHeygenVoiceId() => _get(_keyHgVoiceId);
  static Future<void> setHeygenVoiceId(String v) => _set(_keyHgVoiceId, v);
  static Future<String> getHeygenVoiceName() => _get(_keyHgVoiceName);
  static Future<void> setHeygenVoiceName(String v) => _set(_keyHgVoiceName, v);
}
