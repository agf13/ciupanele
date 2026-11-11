import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/symbol.dart';
import '../providers/slot_machine_providers.dart';

class SymbolManager extends ConsumerWidget {
  const SymbolManager({super.key, required this.symbols});
  final List<SlotSymbol> symbols;

  Future<void> _chooseImage(BuildContext context, WidgetRef ref, SlotSymbol symbol) async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, requestFullMetadata: false);
      if (file == null) return;
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      codec.dispose();
      await ref.read(slotMachineProvider.notifier).setImage(symbol.id, file.path);
    } catch (_) {
      if (context.mounted) _message(context, 'That image could not be opened. Choose a different image.');
    }
  }

  Future<void> _chooseSound(BuildContext context, WidgetRef ref, SlotSymbol symbol) async {
    try {
      final result = await FilePicker.pickFile(type: FileType.audio);
      final path = result?.path;
      if (path == null) return;
      await ref.read(slotMachineProvider.notifier).setSound(symbol.id, path);
    } catch (_) {
      if (context.mounted) _message(context, 'That sound could not be imported. Please try another file.');
    }
  }

  static void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: const Color(0xFF211C28),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: colors.outlineVariant.withValues(alpha: .45))),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.tune_rounded, color: colors.primary),
        title: const Text('Your symbols', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Add 5 images and optional sounds'),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: List.generate(5, (index) {
          final symbol = symbols.length > index
              ? symbols[index]
              : SlotSymbol(id: 'symbol-${index + 1}', imagePath: null);
          return _SymbolRow(
            symbol: symbol,
            number: index + 1,
            onImage: () => _chooseImage(context, ref, symbol),
            onSound: () => _chooseSound(context, ref, symbol),
            onRemoveImage: () async {
              try { await ref.read(slotMachineProvider.notifier).removeImage(symbol.id); }
              catch (_) { if (context.mounted) _message(context, 'Could not remove this image.'); }
            },
            onRemoveSound: () async {
              try { await ref.read(slotMachineProvider.notifier).removeSound(symbol.id); }
              catch (_) { if (context.mounted) _message(context, 'Could not remove this sound.'); }
            },
          );
        }),
      ),
    );
  }
}

class _SymbolRow extends StatelessWidget {
  const _SymbolRow({required this.symbol, required this.number, required this.onImage, required this.onSound, required this.onRemoveImage, required this.onRemoveSound});
  final SlotSymbol symbol;
  final int number;
  final VoidCallback onImage;
  final VoidCallback onSound;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveSound;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageExists = symbol.imagePath != null && File(symbol.imagePath!).existsSync();
    final soundExists = symbol.soundPath != null && File(symbol.soundPath!).existsSync();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF2B2532), borderRadius: BorderRadius.circular(17)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(width: 54, height: 54, child: imageExists
              ? Image.file(File(symbol.imagePath!), fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))
              : const ColoredBox(color: Color(0xFF3A3340), child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white54))),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Symbol $number', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(soundExists ? 'Image ready · Sound added' : imageExists ? 'Image ready · No sound' : 'Image required',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          PopupMenuButton<String>(
            tooltip: 'Manage symbol $number',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              switch (action) {
                case 'image': onImage();
                case 'sound': onSound();
                case 'remove-image': onRemoveImage();
                case 'remove-sound': onRemoveSound();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'image', child: Text(imageExists ? 'Replace image' : 'Add image')),
              PopupMenuItem(value: 'sound', child: Text(soundExists ? 'Replace sound' : 'Add sound')),
              if (imageExists) const PopupMenuItem(value: 'remove-image', child: Text('Remove image')),
              if (soundExists) const PopupMenuItem(value: 'remove-sound', child: Text('Remove sound')),
            ],
          ),
        ]),
      ),
    );
  }
}
