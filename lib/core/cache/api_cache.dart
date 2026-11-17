import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кэш ответов API в SharedPreferences с gzip-сжатием.
///
/// По умолчанию данные живут 5 минут, чтобы не спамить публичный API.
/// Тяжёлые ответы (каталог предметов, каталог героев, история матчей)
/// кэшируются в компактном виде на стороне репозиториев.
class ApiCache {
  ApiCache({this.ttl = const Duration(minutes: 5)});

  static const String _prefix = 'dl_cache_';

  /// localStorage в вебе ограничен ~5 МБ: не пишем заведомо огромные строки.
  static const int _maxPayloadChars = 4200000;

  final Duration ttl;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String keyFor(String path, [Map<String, dynamic>? query]) {
    final buffer = StringBuffer(path);
    if (query != null && query.isNotEmpty) {
      final keys = query.keys.toList()..sort();
      for (final key in keys) {
        final value = query[key];
        if (value == null) {
          continue;
        }
        final text = value is Iterable ? value.join(',') : value.toString();
        buffer.write('|$key=$text');
      }
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-=,.]'), '_')
        .toString();
  }

  Future<dynamic> read(String key, {Duration? overrideTtl}) async {
    try {
      final prefs = await _instance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final envelope = jsonDecode(raw);
      if (envelope is! Map) {
        await prefs.remove('$_prefix$key');
        return null;
      }

      final savedAt = _asInt(envelope['ts']);
      final maxAge = (overrideTtl ?? ttl).inMilliseconds;
      final age = DateTime.now().millisecondsSinceEpoch - savedAt;
      if (savedAt <= 0 || age < 0 || age > maxAge) {
        await prefs.remove('$_prefix$key');
        return null;
      }

      final encoded = envelope['data'];
      if (encoded is! String || encoded.isEmpty) {
        return null;
      }

      final bytes = GZipDecoder().decodeBytes(base64Decode(encoded));
      return jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, dynamic data, {Duration? overrideTtl}) async {
    try {
      final text = jsonEncode(data);
      final compressed = GZipEncoder().encode(utf8.encode(text));
      final encoded = base64Encode(compressed);
      final payload = jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'ttl': (overrideTtl ?? ttl).inMilliseconds,
        'data': encoded,
      });

      if (payload.length > _maxPayloadChars) {
        return;
      }

      final prefs = await _instance();
      try {
        await prefs.setString('$_prefix$key', payload);
      } catch (_) {
        // Квота закончилась — чистим старые записи и пробуем ещё раз.
        await clear();
        try {
          await prefs.setString('$_prefix$key', payload);
        } catch (_) {
          // Кэш не критичен: приложение работает и без него.
        }
      }
    } catch (_) {
      // Некорректные данные просто не кэшируем.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _instance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_prefix))
          .toList(growable: false);
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Ничего страшного, если очистить не удалось.
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
