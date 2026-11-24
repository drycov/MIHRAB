import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:material_ui/material_ui.dart';
import '../../app/theme.dart';
import '../../shared/islamic_ornaments.dart';
import '../../infrastructure/firebase_runtime.dart';
import '../../l10n/mihrab_strings.dart';

class FirebaseScreen extends StatefulWidget {
  const FirebaseScreen({super.key});
  @override
  State<FirebaseScreen> createState() => _FirebaseScreenState();
}
class _FirebaseScreenState extends State<FirebaseScreen> {
  String? token;
  bool busy = false;
  String? result;
  StreamSubscription<String>? refresh;
  StreamSubscription<RemoteMessage>? messages;
  Future<void> change(bool enable) async {
    setState(() { busy=true; result=null; });
    try {
      if(enable) {
        final value=await FirebaseRuntime.enableMessaging();
        if(!mounted) return;
        if(value==null) {
          result='FCM недоступен';
        } else {
          token=value;
          await refresh?.cancel();
          await messages?.cancel();
          if(!mounted) return;
          refresh=FirebaseMessaging.instance.onTokenRefresh.listen((value){
            if(mounted) setState(()=>token=value);
          });
          messages=FirebaseMessaging.onMessage.listen((message){
            if(!mounted) return;
            final notification=message.notification;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:Text([notification?.title,notification?.body].whereType<String>().join(' — ')),
            ));
          });
        }
      } else {
        await FirebaseRuntime.disableMessaging();
        await refresh?.cancel();
        await messages?.cancel();
        token=null;
      }
    } catch (_) { result='FCM недоступен'; }
    if(mounted) setState(()=>busy=false);
  }
  @override
  void dispose() {
    refresh?.cancel();
    messages?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final available=FirebaseRuntime.configured && !kIsWeb;
    return Scaffold(
      appBar:AppBar(title:const Text('Firebase / FCM')),
      body:ListView(padding:const EdgeInsets.all(MihrabTokens.space),children:[
        IslamicSectionTitle('FCM'),
        IslamicCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(context.tr(available?'FCM готов к настройке':'FCM недоступен')),
          const SizedBox(height:MihrabTokens.spaceSm),
          Text(context.tr('FCM передаёт идентификатор устройства в Firebase для удалённых уведомлений.')),
          if(result!=null) Text(context.tr(result!)),
          if(token!=null) Text(context.tr('Токен FCM получен')),
          FilledButton(onPressed:available&&!busy?()=>change(true):null,child:Text(context.tr('Разрешить FCM'))),
          OutlinedButton(onPressed:available&&!busy?()=>change(false):null,child:Text(context.tr('Отключить FCM'))),
          if(token!=null) TextButton(onPressed:busy?null:()=>FirebaseRuntime.copyToken(token!),child:Text(context.tr('Копировать токен FCM'))),
        ])),
      ]),
    );
  }
}
