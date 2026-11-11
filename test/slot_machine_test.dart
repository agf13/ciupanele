import 'package:flutter_test/flutter_test.dart';
import 'package:ciupanele/features/slot_machine/domain/entities/symbol.dart';
import 'package:ciupanele/features/slot_machine/domain/usecases/evaluate_spin.dart';

void main() {
  const evaluate = EvaluateSpin();
  const apple = SlotSymbol(id: 'apple', imagePath: '/apple.jpg', soundPath: '/apple.mp3');
  const cherry = SlotSymbol(id: 'cherry', imagePath: '/cherry.jpg');
  const lemon = SlotSymbol(id: 'lemon', imagePath: '/lemon.jpg');

  group('EvaluateSpin', () {
    test('three identical symbol IDs produce a win', () {
      final result = evaluate([apple, apple, apple]);
      expect(result.isWin, isTrue);
      expect(result.winningSymbol?.id, 'apple');
    });

    test('three different symbols do not produce a win', () {
      final result = evaluate([apple, cherry, lemon]);
      expect(result.isWin, isFalse);
      expect(result.winningSymbol, isNull);
    });

    test('two identical symbols and one different symbol do not produce a win', () {
      expect(evaluate([cherry, cherry, apple]).isWin, isFalse);
    });

    test('the winning symbol is identified by unique ID', () {
      final anotherAppleWithDifferentMedia = const SlotSymbol(id: 'apple', imagePath: '/renamed-file.png');
      expect(evaluate([apple, anotherAppleWithDifferentMedia, apple]).winningSymbol?.id, 'apple');
    });

    test('a missing sound does not prevent winning', () {
      final result = evaluate([cherry, cherry, cherry]);
      expect(result.isWin, isTrue);
      expect(result.winningSymbol?.soundPath, isNull);
    });

    test('rejects a roll with a reel count other than three', () {
      expect(() => evaluate([apple]), throwsArgumentError);
    });
  });
}
