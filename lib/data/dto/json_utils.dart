/// Безопасное чтение полей: Deadlock API иногда отдаёт числа строками,
/// иногда `null`, а вложенные объекты могут отсутствовать.
int jsonInt(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

double jsonDouble(dynamic value, [double fallback = 0]) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

String jsonString(dynamic value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

bool jsonBool(dynamic value, [bool fallback = false]) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true' || lower == '1') {
      return true;
    }
    if (lower == 'false' || lower == '0') {
      return false;
    }
  }
  return fallback;
}

Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<dynamic> jsonList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const [];
}
