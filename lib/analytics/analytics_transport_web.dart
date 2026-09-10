import 'dart:convert';
import 'dart:js_interop';

@JS('starlightAnalytics.setScreen')
external void _setScreen(
  JSString screenId,
  JSString? overlayId,
  JSNumber? stageId,
);

@JS('starlightAnalytics.trackJson')
external void _trackJson(JSString payload);

@JS('starlightAnalytics.markPointerJson')
external void _markPointerJson(JSString payload);

void analyticsSetScreen(String screenId, String? overlayId, int? stageId) {
  try {
    _setScreen(screenId.toJS, overlayId?.toJS, stageId?.toJS);
  } catch (_) {
    // Analytics must never affect play when runtime config/scripts are absent.
  }
}

void analyticsTrack(Map<String, Object?> payload) {
  try {
    _trackJson(jsonEncode(payload).toJS);
  } catch (_) {}
}

void analyticsMarkPointer(Map<String, Object?> payload) {
  try {
    _markPointerJson(jsonEncode(payload).toJS);
  } catch (_) {}
}
