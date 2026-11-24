enum BookmarkKind { surah, ayah, dua }
class Bookmark {
  const Bookmark({required this.kind,required this.reference,required this.title,this.collection=''});
  final BookmarkKind kind;
  final String reference,title,collection;
  String get id=>'${kind.name}:$reference';
  Bookmark move(String value)=>Bookmark(kind:kind,reference:reference,title:title,collection:value);
  Map<String,dynamic> toJson()=>{'kind':kind.name,'reference':reference,'title':title,'collection':collection};
  factory Bookmark.fromJson(Map<String,dynamic> j){
    final kind=BookmarkKind.values.byName(j['kind'] as String);
    final reference=j['reference'] as String;
    final title=j['title'] as String;
    final collection=j['collection'] as String? ?? '';
    if(title.trim().isEmpty||title.length>200||collection.length>60)throw const FormatException('Invalid bookmark');
    if(kind==BookmarkKind.dua){
      if(!RegExp(r'^[a-z0-9-]{1,80}$').hasMatch(reference))throw const FormatException('Invalid dua');
    }else{
      final parts=reference.split(':');
      final surah=int.tryParse(parts.first)??0;
      if(surah<1||surah>114||parts.length!=(kind==BookmarkKind.ayah?2:1))throw const FormatException('Invalid surah');
      if(kind==BookmarkKind.ayah){final verse=int.tryParse(parts.last)??0;if(verse<1||verse>286)throw const FormatException('Invalid ayah');}
    }
    return Bookmark(kind:kind,reference:reference,title:title,collection:collection);
  }
}
class BookmarkLibrary {
  const BookmarkLibrary({this.items=const [],this.collections=const []});
  final List<Bookmark> items;
  final List<String> collections;
  bool contains(String id)=>items.any((b)=>b.id==id);
  BookmarkLibrary toggle(Bookmark b)=>BookmarkLibrary(collections:collections,items:List.unmodifiable(contains(b.id)?items.where((x)=>x.id!=b.id):[b,...items]));
  BookmarkLibrary addCollection(String name){
    final value=name.trim();
    if(value=='__all__'||value.isEmpty||value.length>60||collections.any((c)=>c.toLowerCase()==value.toLowerCase()))throw const FormatException('Invalid or duplicate collection');
    return BookmarkLibrary(items:items,collections:List.unmodifiable([...collections,value]));
  }
  BookmarkLibrary move(String id,String collection){
    if(collection.isNotEmpty&&!collections.contains(collection))throw const FormatException('Unknown collection');
    return BookmarkLibrary(collections:collections,items:List.unmodifiable(items.map((b)=>b.id==id?b.move(collection):b)));
  }
  BookmarkLibrary removeCollection(String name)=>BookmarkLibrary(collections:List.unmodifiable(collections.where((c)=>c!=name)),items:List.unmodifiable(items.map((b)=>b.collection==name?b.move(''):b)));
  Map<String,dynamic> toJson()=>{'items':items.map((b)=>b.toJson()).toList(),'collections':collections};
  factory BookmarkLibrary.fromJson(Map<String,dynamic> j){
    final collections=List<String>.from(j['collections'] as List);
    if(collections.any((c)=>c.trim().isEmpty||c.length>60)||collections.map((c)=>c.toLowerCase()).toSet().length!=collections.length)throw const FormatException('Invalid collections');
    final items=(j['items'] as List).map((v)=>Bookmark.fromJson(Map<String,dynamic>.from(v as Map))).toList();
    if(items.map((b)=>b.id).toSet().length!=items.length||items.any((b)=>b.collection.isNotEmpty&&!collections.contains(b.collection)))throw const FormatException('Invalid bookmarks');
    return BookmarkLibrary(items:List.unmodifiable(items),collections:List.unmodifiable(collections));
  }
}
