import 'package:flutter/material.dart';
import 'package:sudoku_game/analytics/starlight_analytics.dart';
import 'package:sudoku_game/l10n/l10n_ext.dart';
import 'package:sudoku_game/presentation/config/play_ui.dart';
import 'package:sudoku_game/presentation/config/play_ui_target.dart';
import 'package:sudoku_game/presentation/widgets/parchment_modal.dart';
import 'package:sudoku_game/release_notifications/release_notification_transport.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseNotificationDialog extends StatefulWidget {
  const ReleaseNotificationDialog({super.key});

  static Future<void> show(BuildContext context) {
    StarlightAnalytics.instance.track('release_notify_open');
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xCC152433),
      builder: (_) => const ReleaseNotificationDialog(),
    );
  }

  @override
  State<ReleaseNotificationDialog> createState() =>
      _ReleaseNotificationDialogState();
}

class _ReleaseNotificationDialogState extends State<ReleaseNotificationDialog> {
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = l10nOf(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await subscribeReleasePush(
        locale: Localizations.localeOf(context).toLanguageTag(),
      );
      if (result == 'denied') {
        StarlightAnalytics.instance.track('release_notify_failed');
        if (mounted) setState(() => _error = l10n.releaseNotifyDenied);
        return;
      }
      if (result == 'unsupported') {
        StarlightAnalytics.instance.track('release_notify_failed');
        if (mounted) setState(() => _error = l10n.releaseNotifyUnsupported);
        return;
      }
      StarlightAnalytics.instance.track('release_notify_success');
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      StarlightAnalytics.instance.track('release_notify_failed');
      if (mounted) setState(() => _error = l10n.releaseNotifyFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openPrivacy() async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final uri = Uri.https(
      'spark.tycheworks.com',
      '/starlight-sudoku/privacy/',
      locale.startsWith('ko') ? null : {'lang': locale},
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return AnalyticsOverlay(
      id: 'release_notification',
      child: PlayUiTokens(
        target: PlayUiTarget.trialEnd,
        builder: (context) => ParchmentModal(
          target: PlayUiTarget.trialEnd,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.releaseNotifyTitle,
                  textAlign: TextAlign.center,
                  style: PlayUi.titleStyle(),
                ),
                const SizedBox(height: 8),
                Text(
                  _submitted
                      ? l10n.releaseNotifySuccess
                      : l10n.releaseNotifyBody,
                  textAlign: TextAlign.center,
                  style: PlayUi.captionStyle().copyWith(
                    fontSize: PlayUi.body,
                    height: 1.35,
                  ),
                ),
                if (!_submitted) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openPrivacy,
                    child: Text(l10n.releaseNotifyPrivacy),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF9D241D)),
                      ),
                    ),
                ],
                ParchmentModalButtonRow(
                  children: [
                    if (!_submitted)
                      ParchmentModalButton(
                        key: const Key('release-notify-submit'),
                        asset: ParchmentModal.exitAsset,
                        label: l10n.releaseNotifySubmit,
                        color: PlayUi.cream,
                        onPressed: _submit,
                      ),
                    ParchmentModalButton(
                      key: const Key('release-notify-close'),
                      asset: ParchmentModal.continueAsset,
                      label: l10n.close,
                      color: PlayUi.ink,
                      onPressed: () {
                        if (!_submitting) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
