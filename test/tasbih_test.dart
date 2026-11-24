import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/tasbih.dart';
import 'package:mihrab/application/tasbih.dart';
import 'package:mihrab/application/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
void main(){
  final now=DateTime.utc(2026,11,24);
  test('completion recorded exactly once',(){
    var s=const TasbihState(target:2);
    s=s.increment(now).increment(now).increment(now);
    expect(s.count,2);expect(s.history.length,1);
    expect(s.reset().count,0);expect(s.reset().history.length,1);
  });
  test('roundtrip and bounded goals',(){
    final s=const TasbihState(target:1).increment(now);
    final copy=TasbihState.fromJson(s.toJson());
    expect(copy.count,1);expect(copy.history.single.completedAt,now);
    expect(()=>s.configure(Dhikr.free,0),throwsRangeError);
  });
  test('serializes concurrent increments and restores state',()async{
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final c=ProviderContainer(overrides:[preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final controller=c.read(tasbihProvider.notifier);
    await controller.configure(Dhikr.free,3);
    await Future.wait(List.generate(5,(_)=>controller.increment()));
    expect(c.read(tasbihProvider).count,3);
    expect(c.read(tasbihProvider).history.length,1);
    final restored=ProviderContainer(overrides:[preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(restored.dispose);
    expect(restored.read(tasbihProvider).count,3);
  });
}
