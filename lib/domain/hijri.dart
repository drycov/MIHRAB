class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year, month, day;
  static const months = ['Мухаррам','Сафар','Раби аль-авваль','Раби ас-сани','Джумада аль-уля','Джумада ас-сани','Раджаб','Шаабан','Рамадан','Шавваль','Зуль-када','Зуль-хиджа'];
  String get label => '$day ${months[month - 1]} $year г.х.';
  String? get event => switch ((month,day)) {
    (1,1) => 'Начало года Хиджры',
    (1,10) => 'Ашура',
    (9,1) => 'Начало Рамадана',
    (10,1) => 'Ораза айт',
    (12,9) => 'День Арафа',
    (12,10) => 'Курбан айт',
    _ => null,
  };
}

abstract final class HijriCalendar {
  // Civil tabular Islamic calendar, epoch 16 July 622 (Julian).
  static const epoch = 1948440;
  static int start(int year, int month) => epoch + (year - 1) * 354 +
      ((3 + 11 * year) ~/ 30) + ((59 * (month - 1) + 1) ~/ 2);

  static HijriDate fromGregorian(DateTime date, {int adjustment = 0}) {
    if (adjustment < -2 || adjustment > 2) throw RangeError.range(adjustment,-2,2);
    final civil = DateTime.utc(date.year,date.month,date.day);
    final jd = 2440588 + civil.difference(DateTime.utc(1970)).inDays + adjustment;
    if (jd < epoch) throw RangeError('Date precedes Hijri epoch');
    var year = (30 * (jd - epoch) + 10646) ~/ 10631;
    while (start(year + 1,1) <= jd) { year++; }
    while (start(year,1) > jd) { year--; }
    var month = 1;
    while (month < 12 && start(year,month + 1) <= jd) { month++; }
    return HijriDate(year,month,jd - start(year,month) + 1);
  }
}
