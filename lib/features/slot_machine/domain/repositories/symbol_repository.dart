import '../entities/symbol.dart';

abstract interface class SymbolRepository {
  Future<List<SlotSymbol>> loadSymbols();
  Future<List<SlotSymbol>> setImage(String id, String sourcePath);
  Future<List<SlotSymbol>> setSound(String id, String sourcePath);
  Future<List<SlotSymbol>> removeImage(String id);
  Future<List<SlotSymbol>> removeSound(String id);
}
