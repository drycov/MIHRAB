enum DuaCategory {
  morning('Утро'), evening('Вечер'), afterPrayer('После намаза'), sleep('Перед сном'), waking('Пробуждение');
  const DuaCategory(this.label);
  final String label;
}
class Dua {
  const Dua(this.id,this.category,this.title,this.arabic,this.transliteration,this.meaning,this.source,this.url,this.repetitions);
  final String id,title,arabic,transliteration,meaning,source,url;
  final DuaCategory category;
  final int repetitions;
}
const duas = <Dua>[
  Dua('morning-praise',DuaCategory.morning,'Прославление Аллаха','سُبْحَانَ اللَّهِ وَبِحَمْدِهِ','Субханаллахи ва бихамдихи','Пречист Аллах, и Ему хвала.','Сахих Муслим 2692','https://sunnah.com/muslim:2692',100),
  Dua('evening-praise',DuaCategory.evening,'Прославление Аллаха','سُبْحَانَ اللَّهِ وَبِحَمْدِهِ','Субханаллахи ва бихамдихи','Пречист Аллах, и Ему хвала.','Сахих Муслим 2692','https://sunnah.com/muslim:2692',100),
  Dua('prayer-tasbih',DuaCategory.afterPrayer,'Тасбих','سُبْحَانَ اللَّهِ','Субханаллах','Пречист Аллах.','Сахих Муслим 597a','https://sunnah.com/muslim/5/188',33),
  Dua('prayer-tahmid',DuaCategory.afterPrayer,'Тахмид','الْحَمْدُ لِلَّهِ','Альхамдулиллях','Хвала Аллаху.','Сахих Муслим 597a','https://sunnah.com/muslim/5/188',33),
  Dua('prayer-takbir',DuaCategory.afterPrayer,'Такбир','اللَّهُ أَكْبَرُ','Аллаху акбар','Аллах велик.','Сахих Муслим 597a','https://sunnah.com/muslim/5/188',33),
  Dua('prayer-tahlil',DuaCategory.afterPrayer,'Завершение зикра','لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ','Ля иляха илляллаху вахдаху ля шарика лях, ляхуль-мульку ва ляхуль-хамду ва хува аля кулли шайин кадир','Нет божества, кроме Аллаха, Единого, без сотоварища. Ему принадлежит власть и хвала, и Он над всякой вещью властен.','Сахих Муслим 597a','https://sunnah.com/muslim/5/188',1),
  Dua('sleep',DuaCategory.sleep,'Дуа перед сном','بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا','Бисмика Аллахумма амуту ва ахья','С Твоим именем, о Аллах, я умираю и оживаю.','Сахих аль-Бухари 6324','https://sunnah.com/bukhari:6324',1),
  Dua('waking',DuaCategory.waking,'Дуа при пробуждении','الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ','Альхамдулилляхиллязи ахьяна бада ма аматана ва иляйхин-нушур','Хвала Аллаху, Который оживил нас после того, как умертвил нас, и к Нему воскресение.','Сахих аль-Бухари 6324','https://sunnah.com/bukhari:6324',1),
];
