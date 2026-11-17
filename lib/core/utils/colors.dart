/// Цвет из строки вида `#RRGGBB` → ARGB int для `Color(...)`.
int? parseHexColor(String value) {
  final text = value.trim().replaceFirst('#', '');
  if (text.length != 6 && text.length != 8) {
    return null;
  }
  final parsed = int.tryParse(text, radix: 16);
  if (parsed == null) {
    return null;
  }
  if (text.length == 6) {
    return 0xFF000000 | parsed;
  }
  return parsed;
}
