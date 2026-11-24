import 'dart:convert';
import 'dart:js_interop';
@JS('mihrabPush.status')
external JSString _status();
@JS('mihrabPush.subscribe')
external JSPromise<JSString> _subscribe(JSString locale, JSString schedule);
@JS('mihrabPush.sync')
external JSPromise<JSString> _sync(JSString schedule);
@JS('mihrabPush.unsubscribe')
external JSPromise<JSString> _unsubscribe();
Map<String,dynamic> pushStatus() {
  try { return jsonDecode(_status().toDart) as Map<String,dynamic>; }
  catch (_) { return const {}; }
}
Future<String> subscribePush(String locale, String schedule) async {
  try { return (await _subscribe(locale.toJS,schedule.toJS).toDart).toDart; }
  catch (_) { return 'error'; }
}
Future<String> syncPush(String schedule) async {
  try { return (await _sync(schedule.toJS).toDart).toDart; }
  catch (_) { return 'error'; }
}
Future<String> unsubscribePush() async {
  try { return (await _unsubscribe().toDart).toDart; }
  catch (_) { return 'error'; }
}
