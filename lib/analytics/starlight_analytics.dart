import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sudoku_game/analytics/analytics_transport.dart';

/// Failure-isolated analytics facade. No method awaits network I/O.
class StarlightAnalytics with WidgetsBindingObserver {
  StarlightAnalytics._();

  static final instance = StarlightAnalytics._();

  final Stopwatch _sessionClock = Stopwatch();
  final List<_ScreenEntry> _screens = [];
  final List<_OverlayEntry> _overlays = [];
  bool _initialized = false;
  bool _foreground = true;
  bool _gamePaused = false;
  int _activeEngagementSeconds = 0;
  int _activePlaySeconds = 0;
  int _screenSeconds = 0;
  int? _stageId;
  String? _puzzleId;

  String get screenId => _screens.isEmpty ? 'unknown' : _screens.last.id;
  String? get overlayId => _overlays.isEmpty ? null : _overlays.last.id;
  int get activePlaySeconds => _activePlaySeconds;

  void initialize() {
    if (_initialized || !kIsWeb) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _sessionClock.start();
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_foreground) {
        return;
      }
      _activeEngagementSeconds++;
      _screenSeconds++;
      if (screenId == 'game' && !_gamePaused) {
        _activePlaySeconds++;
      }
    });
    track('game_open', screenId: 'splash');
  }

  void ready() => track(
    'game_ready',
    screenId: screenId == 'unknown' ? 'splash' : screenId,
  );

  void pushScreen(Object owner, String id, {int? stageId}) {
    if (!kIsWeb) return;
    _screens.removeWhere((entry) => identical(entry.owner, owner));
    _screens.add(_ScreenEntry(owner, id));
    _stageId = stageId ?? _stageId;
    _screenSeconds = 0;
    analyticsSetScreen(screenId, overlayId, _stageId);
    track('screen_view');
  }

  void updateScreen(Object owner, String id, {int? stageId}) {
    if (!kIsWeb || _screens.isEmpty || !identical(_screens.last.owner, owner)) {
      return;
    }
    if (_screens.last.id == id && (stageId == null || stageId == _stageId)) {
      return;
    }
    _emitScreenExit();
    _screens[_screens.length - 1] = _ScreenEntry(owner, id);
    _stageId = stageId ?? _stageId;
    _screenSeconds = 0;
    analyticsSetScreen(screenId, overlayId, _stageId);
    track('screen_view');
  }

  void popScreen(Object owner) {
    if (!kIsWeb) return;
    final wasTop = _screens.isNotEmpty && identical(_screens.last.owner, owner);
    if (wasTop) _emitScreenExit();
    _screens.removeWhere((entry) => identical(entry.owner, owner));
    _screenSeconds = 0;
    analyticsSetScreen(screenId, overlayId, _stageId);
    if (wasTop && _screens.isNotEmpty) track('screen_view');
  }

  void pushOverlay(Object owner, String id) {
    if (!kIsWeb) return;
    _overlays.removeWhere((entry) => identical(entry.owner, owner));
    _overlays.add(_OverlayEntry(owner, id));
    analyticsSetScreen(screenId, overlayId, _stageId);
  }

  void popOverlay(Object owner) {
    if (!kIsWeb) return;
    _overlays.removeWhere((entry) => identical(entry.owner, owner));
    analyticsSetScreen(screenId, overlayId, _stageId);
  }

  void setGameContext({required int stageId, required String puzzleId}) {
    _stageId = stageId;
    _puzzleId = puzzleId;
    analyticsSetScreen(screenId, overlayId, _stageId);
  }

  void setGamePaused(bool paused) => _gamePaused = paused;

  void track(
    String eventName, {
    String? screenId,
    int? stageId,
    int? remainingCells,
    int? mistakeCount,
    int? hintCount,
    String? targetId,
    String? targetType,
    bool? isInteractive,
    Map<String, Object?> properties = const {},
  }) {
    if (!kIsWeb) return;
    analyticsTrack({
      'event_name': eventName,
      'screen_id': screenId ?? this.screenId,
      'overlay_id': overlayId,
      'stage_id': stageId ?? _stageId,
      'puzzle_id': _puzzleId,
      'elapsed_screen_time': _screenSeconds,
      'elapsed_play_time': _activePlaySeconds,
      'remaining_cells': remainingCells,
      'mistake_count': mistakeCount,
      'hint_count': hintCount,
      'target_id': targetId,
      'target_type': targetType,
      'is_interactive': isInteractive,
      'properties': properties,
    });
  }

  void markInteractivePointer(
    PointerDownEvent event,
    Size size, {
    required String targetId,
    String targetType = 'control',
    String? interactionKind,
  }) {
    if (!kIsWeb || size.width <= 0 || size.height <= 0) return;
    analyticsMarkPointer({
      'screen_id': screenId,
      'overlay_id': overlayId,
      'stage_id': _stageId,
      'puzzle_id': _puzzleId,
      'elapsed_screen_time': _screenSeconds,
      'elapsed_play_time': _activePlaySeconds,
      'x_ratio': (event.position.dx / size.width).clamp(0.0, 1.0),
      'y_ratio': (event.position.dy / size.height).clamp(0.0, 1.0),
      'viewport_width': size.width.round(),
      'viewport_height': size.height.round(),
      'target_id': targetId,
      'target_type': targetType,
      'is_interactive': true,
      'properties': interactionKind == null
          ? const {}
          : {'interaction_kind': interactionKind},
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      track(
        'session_end',
        properties: {
          'session_duration': _sessionClock.elapsedMilliseconds / 1000,
          'active_engagement_time': _activeEngagementSeconds,
        },
      );
    } else if (state == AppLifecycleState.resumed) {
      analyticsSetScreen(screenId, overlayId, _stageId);
    }
  }

  void _emitScreenExit() {
    track('screen_exit', properties: {'screen_duration': _screenSeconds});
  }

  @visibleForTesting
  void resetForTest() {
    _screens.clear();
    _overlays.clear();
    _stageId = null;
    _puzzleId = null;
    _activeEngagementSeconds = 0;
    _activePlaySeconds = 0;
    _screenSeconds = 0;
    _gamePaused = false;
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.id,
    required this.child,
    this.stageId,
  });
  final String id;
  final Widget child;
  final int? stageId;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    StarlightAnalytics.instance.pushScreen(
      this,
      widget.id,
      stageId: widget.stageId,
    );
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    StarlightAnalytics.instance.updateScreen(
      this,
      widget.id,
      stageId: widget.stageId,
    );
  }

  @override
  void dispose() {
    StarlightAnalytics.instance.popScreen(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AnalyticsOverlay extends StatefulWidget {
  const AnalyticsOverlay({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  @override
  State<AnalyticsOverlay> createState() => _AnalyticsOverlayState();
}

class _AnalyticsOverlayState extends State<AnalyticsOverlay> {
  @override
  void initState() {
    super.initState();
    StarlightAnalytics.instance.pushOverlay(this, widget.id);
  }

  @override
  void dispose() {
    StarlightAnalytics.instance.popOverlay(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AnalyticsTapRegion extends StatelessWidget {
  const AnalyticsTapRegion({
    super.key,
    required this.targetId,
    required this.child,
    this.targetType = 'control',
    this.interactionKind,
  });
  final String targetId;
  final String targetType;
  final String? interactionKind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) =>
          StarlightAnalytics.instance.markInteractivePointer(
            event,
            MediaQuery.sizeOf(context),
            targetId: targetId,
            targetType: targetType,
            interactionKind: interactionKind,
          ),
      child: child,
    );
  }
}

class _ScreenEntry {
  const _ScreenEntry(this.owner, this.id);
  final Object owner;
  final String id;
}

class _OverlayEntry {
  const _OverlayEntry(this.owner, this.id);
  final Object owner;
  final String id;
}
