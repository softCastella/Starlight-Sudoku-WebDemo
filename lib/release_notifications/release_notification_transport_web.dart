import 'dart:js_interop';

@JS('starlightReleasePush.subscribe')
external JSPromise<JSString> _subscribe(JSString locale);

Future<String> subscribeReleasePush({required String locale}) async {
  return (await _subscribe(locale.toJS).toDart).toDart;
}
