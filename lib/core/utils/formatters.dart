String formatPercent(double value, {int digits = 1}) {
  if (value.isNaN || value.isInfinite) {
    return '—';
  }
  return '${(value * 100).toStringAsFixed(digits)}%';
}

/// Компактный формат больших чисел: 112 705 → «112.7K», 2 936 070 → «2.94M».
String formatCompact(double value) {
  if (value.isNaN || value.isInfinite) {
    return '—';
  }
  final abs = value.abs();
  if (abs >= 1000000000) {
    return '${(value / 1000000000).toStringAsFixed(2)}B';
  }
  if (abs >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (abs >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// KDA-коэффициент: (убийства + помощи) / смерти.
double kdaRatio(int kills, int deaths, int assists) {
  if (deaths <= 0) {
    return (kills + assists).toDouble();
  }
  return (kills + assists) / deaths;
}

String formatKda(int kills, int deaths, int assists) {
  final ratio = kdaRatio(kills, deaths, assists);
  return '$kills/$deaths/$assists · ${ratio.toStringAsFixed(2)}';
}

String formatKdaRatio(int kills, int deaths, int assists) {
  return kdaRatio(kills, deaths, assists).toStringAsFixed(2);
}

/// Длительность матча в формате `mm:ss` (или `h:mm:ss` для долгих игр).
String formatDuration(int seconds) {
  if (seconds <= 0) {
    return '—';
  }
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final minutePart = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutePart:${rest.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}

/// Unix-время (секунды) → `dd.MM.yyyy`.
String formatDateFromSeconds(int seconds) {
  if (seconds <= 0) {
    return '—';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String formatDateFromMillis(int millis) {
  if (millis <= 0) {
    return '—';
  }
  return formatDateFromSeconds(millis ~/ 1000);
}

String formatMonthDayFromSeconds(int seconds) {
  if (seconds <= 0) {
    return '—';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}
