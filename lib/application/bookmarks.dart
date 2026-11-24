import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bookmark.dart';
import 'settings.dart';

final bookmarksProvider=NotifierProvider<BookmarksController,BookmarkLibrary>(BookmarksController.new);
class BookmarksController extends Notifier<BookmarkLibrary>{
  static const key='bookmarks_v1';
  Future<void> _tail=Future.value();
  @override
  BookmarkLibrary build(){
    final raw=ref.watch(preferencesProvider).getString(key);
    return raw==null?const BookmarkLibrary():BookmarkLibrary.fromJson(Map<String,dynamic>.from(jsonDecode(raw) as Map));
  }
  Future<void> _change(BookmarkLibrary Function(BookmarkLibrary) fn){
    final task=_tail.then((_)async{
      final next=fn(state);
      if(!await ref.read(preferencesProvider).setString(key,jsonEncode(next.toJson())))throw StateError('Save failed');
      state=next;
    });
    _tail=task.then<void>((_){},onError:(Object e,StackTrace s){});
    return task;
  }
  Future<void> toggle(Bookmark b)=>_change((s)=>s.toggle(b));
  Future<void> addCollection(String name)=>_change((s)=>s.addCollection(name));
  Future<void> move(String id,String collection)=>_change((s)=>s.move(id,collection));
  Future<void> removeCollection(String name)=>_change((s)=>s.removeCollection(name));
}
