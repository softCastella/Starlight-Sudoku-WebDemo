import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web runtime preserves all five UTM parameters', () {
    final source = File('web/analytics.js').readAsStringSync();
    for (final key in [
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'utm_content',
      'utm_term',
    ]) {
      expect(source, contains("'$key'"));
    }
    expect(source, contains("sessionStorage.setItem('starlight_utm_v1'"));
    expect(source, contains('decorateUrl'));
  });

  test('landing loads analytics before emitting its funnel events', () {
    final landing = File('web/landing/index.html').readAsStringSync();
    expect(landing, contains('<script src="../analytics-config.js"></script>'));
    expect(landing, contains('event_name: "landing_view"'));
    expect(landing, contains('event_name: "landing_cta_click"'));
  });

  test('runtime defaults to disabled without deployment configuration', () {
    final config = File('web/analytics-config.js').readAsStringSync();
    expect(config, contains('collectorUrl: ""'));
    expect(config, contains('gaMeasurementId: ""'));
    expect(config, contains('enabled: false'));
  });

  test('fine pointer data is excluded from the GA major event set', () {
    final source = File('web/analytics.js').readAsStringSync();
    final gaSet = RegExp(r'majorGaEvents=new Set\(\[(.*?)\]\)')
        .firstMatch(source)!
        .group(1)!;
    expect(gaSet, isNot(contains('pointer_tap')));
    expect(gaSet, isNot(contains('cell_select')));
  });

  test('game dialog variants expose heatmap overlay ids', () {
    final retry = File('lib/presentation/widgets/retry_puzzle_dialog.dart')
        .readAsStringSync();
    final exit = File('lib/presentation/widgets/exit_game_dialog.dart')
        .readAsStringSync();
    expect(retry, contains("id: 'retry'"));
    expect(exit, contains("id: 'exit'"));
  });
}
