import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings.dart';
final localeProvider=NotifierProvider<LocaleController,Locale?>(LocaleController.new);
class LocaleController extends Notifier<Locale?>{
  static const key='app_locale_v1';
  static const codes=['ru','kk','ar','en'];
  @override
  Locale? build(){
    final saved=ref.watch(preferencesProvider).getString(key);
    return codes.contains(saved)?Locale(saved!):null;
  }
  Future<void> change(String? code)async{
    if(code!=null&&!codes.contains(code))throw ArgumentError('Unsupported locale');
    final prefs=ref.read(preferencesProvider);
    final ok=code==null?await prefs.remove(key):await prefs.setString(key,code);
    if(!ok)throw StateError('Locale save failed');
    state=code==null?null:Locale(code);
  }
}
