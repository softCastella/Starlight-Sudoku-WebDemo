import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_game/l10n/app_localizations.dart';
import 'package:sudoku_game/presentation/config/app_fonts.dart';
import 'package:sudoku_game/presentation/config/play_ui.dart';
import 'package:sudoku_game/presentation/config/play_ui_target.dart';
import 'package:sudoku_game/presentation/config/play_ui_tune.dart';
import 'package:sudoku_game/presentation/widgets/oval_image_button.dart';
import 'package:sudoku_game/presentation/widgets/parchment_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Future.wait([
      (FontLoader(
        AppFonts.family,
      )..addFont(rootBundle.load('assets/fonts/StarlightSans.ttf'))).load(),
      (FontLoader(
        AppFonts.fallback.first,
      )..addFont(rootBundle.load('assets/fonts/StarlightSansCJK.ttf'))).load(),
    ]);
  });

  test('short label keeps 15px and stays under the cap', () {
    final layout = OvalButtonLayout.forLabel(
      '닫기',
      direction: TextDirection.ltr,
    );
    expect(layout.fontSize, PlayUi.button);
    expect(layout.width, greaterThanOrEqualTo(PlayUi.buttonMinWidth));
    expect(layout.width, lessThanOrEqualTo(PlayUi.buttonMaxWidth));
    expect(layout.height, layout.width / PlayUi.ovalAspect);
    expect(
      layout.sideInset,
      closeTo(layout.width * PlayUi.ovalEndFraction, 0.01),
    );
  });

  test('long label hits the cap then shrinks no lower than 11', () {
    final layout = OvalButtonLayout.forLabel(
      'Keep playing forever and ever',
      direction: TextDirection.ltr,
      maxWidth: 140,
    );
    expect(layout.width, 140);
    expect(layout.fontSize, greaterThanOrEqualTo(PlayUi.minType));
    expect(layout.fontSize, lessThanOrEqualTo(PlayUi.button));
  });

  test('parent narrower than min width does not overflow it', () {
    final layout = OvalButtonLayout.forLabel(
      'Next',
      direction: TextDirection.ltr,
      maxWidth: 80,
    );
    expect(layout.width, lessThanOrEqualTo(80));
    expect(layout.fontSize, greaterThanOrEqualTo(PlayUi.minType));
  });

  testWidgets('long modal labels keep their font and fit at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 843);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final localeId in ['ko', 'en', 'ja', 'zh', 'zh_TW']) {
      final locale = PlayUiTune.localeFromId(localeId);
      final l10n = lookupAppLocalizations(locale);
      for (final label in [
        l10n.releaseNotifyButton,
        l10n.releaseNotifySubmit,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: ThemeData(
              fontFamily: AppFonts.family,
              fontFamilyFallback: AppFonts.fallback,
            ),
            home: Scaffold(
              body: Center(
                child: ParchmentModal(
                  target: PlayUiTarget.trialEnd,
                  child: ParchmentModalButtonRow(
                    children: [
                      ParchmentModalButton(
                        key: const Key('long-modal-button'),
                        asset: ParchmentModal.exitAsset,
                        label: label,
                        color: PlayUi.cream,
                        onPressed: () {},
                      ),
                      ParchmentModalButton(
                        key: const Key('close-modal-button'),
                        asset: ParchmentModal.continueAsset,
                        label: l10n.close,
                        color: PlayUi.ink,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final text = tester.widget<Text>(find.text(label));
        final textContext = tester.element(find.text(label));
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: DefaultTextStyle.of(textContext).style.merge(text.style),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final requiredWidth =
            painter.width +
            PlayUi.kOvalCompactWidth * PlayUi.ovalEndFraction * 2 +
            16;
        final longSize = tester.getSize(
          find.byKey(const Key('long-modal-button')),
        );
        final closeSize = tester.getSize(
          find.byKey(const Key('close-modal-button')),
        );
        expect(text.style?.fontSize, 11, reason: '$localeId: $label');
        expect(
          longSize.width,
          greaterThanOrEqualTo(requiredWidth - 0.5),
          reason: '$localeId: $label',
        );
        expect(
          longSize.height,
          closeTo(closeSize.height, 0.5),
          reason: '$localeId: $label',
        );
        painter.dispose();
      }
    }
  });

  testWidgets('opening label grows the plain middle at the same font size', (
    tester,
  ) async {
    for (final localeId in ['ko', 'en', 'ja', 'zh', 'zh_TW']) {
      final locale = PlayUiTune.localeFromId(localeId);
      final label = lookupAppLocalizations(locale).lightFirstWindow;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          theme: ThemeData(
            fontFamily: AppFonts.family,
            fontFamilyFallback: AppFonts.fallback,
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 262,
                child: PlayUiScope(
                  target: PlayUiTarget.openingButton,
                  localeId: localeId,
                  child: OvalImageButton(
                    key: const Key('opening-long-button'),
                    label: label,
                    width: PlayUi.kOvalCompactWidth,
                    expandToFitLabel: true,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final button = tester.getSize(
        find.byKey(const Key('opening-long-button')),
      );
      final text = tester.widget<Text>(find.text(label));
      final textContext = tester.element(find.text(label));
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: DefaultTextStyle.of(textContext).style.merge(text.style),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final requiredWidth =
          painter.width +
          PlayUi.kOvalCompactWidth * PlayUi.ovalEndFraction * 2 +
          16;
      expect(text.style?.fontSize, 11, reason: localeId);
      expect(
        button.width,
        greaterThanOrEqualTo(requiredWidth - 0.5),
        reason: localeId,
      );
      expect(
        button.height,
        closeTo(PlayUi.kOvalCompactWidth / PlayUi.ovalAspect, 0.5),
        reason: localeId,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('opening-long-button')),
          matching: find.byType(Image),
        ),
        findsAtLeastNWidgets(3),
        reason: localeId,
      );
      painter.dispose();
    }
  });
}
