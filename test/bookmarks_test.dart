import 'package:flutter_test/flutter_test.dart';
import 'package:mihrab/domain/bookmark.dart';
import 'package:mihrab/application/bookmarks.dart';
import 'package:mihrab/application/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
void main(){
  const b=Bookmark(kind:BookmarkKind.ayah,reference:'2:255',title:'Аят 2:255');
  test('collection deletion preserves bookmarks',(){
    final s=const BookmarkLibrary().toggle(b).addCollection('Чтение').move(b.id,'Чтение');
    final restored=BookmarkLibrary.fromJson(s.toJson());
    expect(restored.items.single.collection,'Чтение');
    expect(restored.removeCollection('Чтение').items.single.collection,'');
    expect(restored.toggle(b).items,isEmpty);
  });
  test('serialized writes preserve distinct bookmarks',()async{
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final c=ProviderContainer(overrides:[preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final controller=c.read(bookmarksProvider.notifier);
    await Future.wait([controller.toggle(b),controller.toggle(const Bookmark(kind:BookmarkKind.dua,reference:'sleep',title:'Сон'))]);
    expect(c.read(bookmarksProvider).items.length,2);
    final restored=ProviderContainer(overrides:[preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(restored.dispose);
    expect(restored.read(bookmarksProvider).contains(b.id),isTrue);
  });
}
