import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/bookmarks.dart';
import '../../domain/bookmark.dart';

class BookmarkButton extends ConsumerWidget{
  const BookmarkButton({super.key,required this.bookmark});
  final Bookmark bookmark;
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final saved=ref.watch(bookmarksProvider.select((s)=>s.contains(bookmark.id)));
    return IconButton(tooltip:saved?'Удалить из избранного':'В избранное',icon:Icon(saved?Icons.bookmark:Icons.bookmark_border),onPressed:()async{
      try{await ref.read(bookmarksProvider.notifier).toggle(bookmark);}
      catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Не удалось сохранить закладку')));}
    });
  }
}
