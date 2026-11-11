import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/symbol.dart';
import '../providers/slot_machine_providers.dart';
import '../widgets/reel.dart';
import '../widgets/symbol_manager.dart';

class SlotMachineScreen extends ConsumerWidget {
  const SlotMachineScreen({super.key});

  Future<void> _spin(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(slotMachineProvider.notifier).spin();
    if (result == null || !context.mounted || !result.isWin) return;
    await playWinningSound(ref, result.winningSymbol!);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _WinDialog(symbol: result.winningSymbol!),
    );
    ref.read(slotMachineProvider.notifier).resetTitleClickCount();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slotMachineProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => ref.read(slotMachineProvider.notifier).resetTitleClickCount(),
        child: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 390;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(narrow ? 16 : 24, 18, narrow ? 16 : 24, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: ref.read(slotMachineProvider.notifier).registerTitleClick,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.casino_rounded, color: colors.primary, size: 25),
                        const SizedBox(width: 9),
                        Text('CIUPANELE', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 3, color: colors.onSurface)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text('A little luck, a lot of fun', style: TextStyle(color: colors.onSurfaceVariant, letterSpacing: .5)),
                    const SizedBox(height: 28),
                    Container(
                      padding: EdgeInsets.all(narrow ? 11 : 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312337),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE68A4D), width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x77330F25), blurRadius: 28, offset: Offset(0, 12))],
                      ),
                      child: Row(
                        children: List.generate(3, (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: narrow ? 3 : 7),
                            child: Reel(symbol: state.reels.length > index ? state.reels[index] : null,
                              spinning: state.spinning && !state.stoppedReels[index],
                              available: state.symbols.where((s) => s.imagePath != null).toList()),
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 220,
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: state.ready && !state.spinning ? () => _spin(context, ref) : null,
                        icon: state.spinning
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.play_arrow_rounded, size: 26),
                        label: Text(state.spinning ? 'SPINNING' : 'SPIN', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.ready ? 'Match all three symbols to win!' : 'Add an image to all five symbols to play.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    if (state.error case final error?) ...[
                      const SizedBox(height: 8),
                      Text(error, style: TextStyle(color: colors.error), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 26),
                    SymbolManager(symbols: state.symbols),
                    const SizedBox(height: 20),
                    Text('Your images and sounds stay on this device.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        }),
        ),
      ),
    );
  }
}

class _WinDialog extends StatelessWidget {
  const _WinDialog({required this.symbol});
  final SlotSymbol symbol;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF302337),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Color(0xFFFFC45B), width: 2)),
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.stars_rounded, size: 52, color: Color(0xFFFFC45B)),
        const SizedBox(height: 8),
        const Text('You win!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        SizedBox(width: 92, height: 92, child: Image.file(File(symbol.imagePath!), fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.celebration_rounded, size: 54, color: Color(0xFFFFC45B)))),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('NICE!')),
      ]),
    ),
  );
}
