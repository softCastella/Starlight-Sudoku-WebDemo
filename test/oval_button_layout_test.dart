import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_game/presentation/config/play_ui.dart';
import 'package:sudoku_game/presentation/widgets/oval_image_button.dart';
import 'package:sudoku_game/presentation/widgets/parchment_modal.dart';

Finder _buttonWithLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

double _requiredCompactWidth(BuildContext context, String label) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: PlayUi.buttonStyle()),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return painter.width +
      PlayUi.kOvalCompactWidth * PlayUi.ovalEndFraction * 2 +
      16;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('short label keeps 15px and stays under the cap', () {
    final layout = OvalButtonLayout.forLabel(
      '닫기',
      direction: TextDirection.ltr,
    );
    expect(layout.fontSize, PlayUi.button);
    expect(layout.width, greaterThanOrEqualTo(PlayUi.buttonMinWidth));
    expect(layout.width, lessThanOrEqualTo(PlayUi.buttonMaxWidth));
    expect(layout.height, layout.width / PlayUi.ovalAspect);
    expect(layout.sideInset, closeTo(layout.width * PlayUi.ovalEndFraction, 0.01));
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

  testWidgets('compact oval grows to the Korean and English label width', (
    WidgetTester tester,
  ) async {
    for (final label in ['첫 창문을 밝히기', 'Light the first window']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OvalImageButton(
                label: label,
                width: PlayUi.kOvalCompactWidth,
                expandToFitLabel: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final button = _buttonWithLabel(label);
      final context = tester.element(find.text(label));
      expect(
        tester.getSize(button).width,
        greaterThanOrEqualTo(_requiredCompactWidth(context, label) - 0.1),
      );
      expect(
        tester.getSize(button).height,
        closeTo(PlayUi.kOvalCompactWidth / PlayUi.ovalAspect, 0.1),
      );
    }
  });

  testWidgets('modal row preserves each long label width', (
    WidgetTester tester,
  ) async {
    const longLabel = 'Allow phone notification';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: ParchmentModalButtonRow(
                children: [
                  ParchmentModalButton(
                    asset: ParchmentModal.exitAsset,
                    label: longLabel,
                    color: PlayUi.cream,
                    onPressed: () {},
                  ),
                  ParchmentModalButton(
                    asset: ParchmentModal.continueAsset,
                    label: 'Close',
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

    final context = tester.element(find.text(longLabel));
    expect(
      tester.getSize(_buttonWithLabel(longLabel)).width,
      greaterThanOrEqualTo(_requiredCompactWidth(context, longLabel) - 0.1),
    );
  });
}
