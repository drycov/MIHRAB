import 'dart:convert';
import 'dart:js_interop';

@JS('mihrabPwa.status')
external JSString _status();
@JS('mihrabPwa.install')
external JSPromise<JSBoolean> _install();
@JS('mihrabPwa.checkUpdate')
external JSPromise<JSBoolean> _checkUpdate();

Map<String, dynamic> pwaStatus() {
  try {
    return jsonDecode(_status().toDart) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }
}

Future<bool> installPwa() async {
  try {
    return (await _install().toDart).toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> checkPwaUpdate() async {
  try {
    return (await _checkUpdate().toDart).toDart;
  } catch (_) {
    return false;
  }
}
