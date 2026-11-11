import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_symbol_repository.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/repositories/symbol_repository.dart';
import '../../domain/usecases/evaluate_spin.dart';

final symbolRepositoryProvider = Provider<SymbolRepository>((ref) => LocalSymbolRepository());
final evaluateSpinProvider = Provider((ref) => const EvaluateSpin());
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

class SlotMachineState {
  const SlotMachineState({
    required this.symbols,
    required this.reels,
    this.spinning = false,
    this.stoppedReels = const [true, true, true],
    this.error,
  });

  final List<SlotSymbol> symbols;
  final List<SlotSymbol?> reels;
  final bool spinning;
  final List<bool> stoppedReels;
  final String? error;
  bool get ready => symbols.length == 5 && symbols.every((s) => s.imagePath != null);
}

final slotMachineProvider = NotifierProvider<SlotMachineController, SlotMachineState>(SlotMachineController.new);

class SlotMachineController extends Notifier<SlotMachineState> {
  final _random = Random();
  var _titleClickCount = 0;

  void registerTitleClick() => _titleClickCount++;

  void resetTitleClickCount() => _titleClickCount = 0;

  @override
  SlotMachineState build() {
    final repository = ref.read(symbolRepositoryProvider);
    Future.microtask(() async {
      try {
        final symbols = await repository.loadSymbols();
        state = SlotMachineState(symbols: symbols, reels: List.filled(3, null));
      } catch (error) {
        state = SlotMachineState(symbols: const [], reels: List.filled(3, null), error: error.toString());
      }
    });
    return const SlotMachineState(symbols: [], reels: [null, null, null]);
  }

  Future<void> setImage(String id, String path) => _update((repo) => repo.setImage(id, path));
  Future<void> setSound(String id, String path) => _update((repo) => repo.setSound(id, path));
  Future<void> removeImage(String id) => _update((repo) => repo.removeImage(id));
  Future<void> removeSound(String id) => _update((repo) => repo.removeSound(id));

  Future<void> _update(Future<List<SlotSymbol>> Function(SymbolRepository) action) async {
    try {
      final updated = await action(ref.read(symbolRepositoryProvider));
      state = SlotMachineState(symbols: updated, reels: state.reels);
    } catch (error) {
      state = SlotMachineState(
        symbols: state.symbols,
        reels: state.reels,
        error: 'Could not save that file. Please try again.',
      );
    }
  }

  Future<SpinResult?> spin() async {
    if (!state.ready || state.spinning) return null;
    final candidates = state.symbols.where((s) => s.imagePath != null).toList();
    final symbols = _titleClickCount == 0
        ? List.generate(3, (_) => candidates[_random.nextInt(candidates.length)])
        : List<SlotSymbol>.filled(
            3,
            candidates[(_titleClickCount - 1) % candidates.length],
          );
    final result = ref.read(evaluateSpinProvider)(symbols);
    state = SlotMachineState(
      symbols: state.symbols,
      reels: List.filled(3, null),
      spinning: true,
      stoppedReels: const [false, false, false],
    );
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration(milliseconds: 1050 + i * 380));
      state = SlotMachineState(
        symbols: state.symbols,
        reels: List.generate(3, (index) => index <= i ? result.symbols[index] : null),
        spinning: i < 2,
        stoppedReels: List.generate(3, (index) => index <= i),
      );
    }
    return result;
  }
}

Future<void> playWinningSound(WidgetRef ref, SlotSymbol symbol) async {
  final path = symbol.soundPath;
  if (path == null) return;
  try {
    await ref.read(audioPlayerProvider).stop();
    await ref.read(audioPlayerProvider).play(DeviceFileSource(path));
  } catch (_) {
    // A missing or unsupported sound must never interrupt a completed spin.
  }
}
