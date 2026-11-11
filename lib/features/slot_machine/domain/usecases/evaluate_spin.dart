import '../entities/symbol.dart';

class SpinResult {
  const SpinResult({required this.symbols, required this.winningSymbol});

  final List<SlotSymbol> symbols;
  final SlotSymbol? winningSymbol;

  bool get isWin => winningSymbol != null;
}

class EvaluateSpin {
  const EvaluateSpin();

  SpinResult call(List<SlotSymbol> symbols) {
    if (symbols.length != 3) {
      throw ArgumentError.value(symbols.length, 'symbols.length', 'A spin needs exactly three symbols');
    }
    final firstId = symbols.first.id;
    final winner = symbols.every((symbol) => symbol.id == firstId) ? symbols.first : null;
    return SpinResult(symbols: List.unmodifiable(symbols), winningSymbol: winner);
  }
}
