String two(int n) => n.toString().padLeft(2, '0');
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String formatDate(DateTime d) => '${two(d.day)}.${two(d.month)}.${d.year}';
String formatRemaining(Duration d) {
  final s = d.isNegative ? 0 : (d.inMilliseconds + 999) ~/ 1000;
  return [s ~/ 3600, s ~/ 60 % 60, s % 60].map(two).join(':');
}
