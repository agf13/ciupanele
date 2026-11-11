import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/symbol.dart';
import '../../domain/repositories/symbol_repository.dart';

class LocalSymbolRepository implements SymbolRepository {
  static const _ids = ['symbol-1', 'symbol-2', 'symbol-3', 'symbol-4', 'symbol-5'];
  Directory? _root;

  Future<Directory> get _directory async {
    if (_root != null) return _root!;
    if (Platform.isLinux) {
      final xdgDataHome = Platform.environment['XDG_DATA_HOME'];
      final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
      final dataHome = xdgDataHome != null && xdgDataHome.isNotEmpty
          ? xdgDataHome
          : p.join(home, '.local', 'share');
      _root = Directory(p.join(dataHome, 'ciupanele'));
    } else {
      _root = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'ciupanele'));
    }
    return _root!;
  }

  Future<File> get _metadata async => File(p.join((await _directory).path, 'symbols.json'));

  @override
  Future<List<SlotSymbol>> loadSymbols() async {
    final file = await _metadata;
    Map<String, dynamic> stored;
    try {
      stored = file.existsSync()
          ? jsonDecode(await file.readAsString()) as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (_) {
      stored = <String, dynamic>{};
    }
    final list = <SlotSymbol>[];
    for (final id in _ids) {
      final raw = stored[id];
      final map = raw is Map ? raw : const <String, dynamic>{};
      String? validPath(Object? path) {
        if (path is String && path.isNotEmpty && File(path).existsSync()) return path;
        return null;
      }
      list.add(SlotSymbol(
        id: id,
        imagePath: validPath(map['imagePath']),
        soundPath: validPath(map['soundPath']),
      ));
    }
    return list;
  }

  @override
  Future<List<SlotSymbol>> setImage(String id, String sourcePath) async {
    final symbols = await loadSymbols();
    final destination = await _copyIntoApp(sourcePath, id, 'image');
    final updated = symbols.map((s) => s.id == id ? s.copyWith(imagePath: destination) : s).toList();
    await _save(updated);
    return updated;
  }

  @override
  Future<List<SlotSymbol>> setSound(String id, String sourcePath) async {
    final symbols = await loadSymbols();
    final destination = await _copyIntoApp(sourcePath, id, 'sound');
    final updated = symbols.map((s) => s.id == id ? s.copyWith(soundPath: destination) : s).toList();
    await _save(updated);
    return updated;
  }

  Future<String> _copyIntoApp(String sourcePath, String id, String kind) async {
    final source = File(sourcePath);
    if (!await source.exists()) throw FileSystemException('Selected file is no longer available', sourcePath);
    final directory = await _directory;
    await directory.create(recursive: true);
    final extension = p.extension(sourcePath);
    final destination = File(p.join(directory.path, '$id-$kind$extension'));
    await source.copy(destination.path);
    return destination.path;
  }

  @override
  Future<List<SlotSymbol>> removeImage(String id) async {
    final symbols = await loadSymbols();
    final selected = symbols.firstWhere((s) => s.id == id);
    await _delete(selected.imagePath);
    await _delete(selected.soundPath);
    final updated = symbols.map((s) => s.id == id ? s.copyWith(imagePath: '', clearSound: true) : s).toList();
    await _save(updated);
    return updated;
  }

  @override
  Future<List<SlotSymbol>> removeSound(String id) async {
    final symbols = await loadSymbols();
    final selected = symbols.firstWhere((s) => s.id == id);
    await _delete(selected.soundPath);
    final updated = symbols.map((s) => s.id == id ? s.copyWith(clearSound: true) : s).toList();
    await _save(updated);
    return updated;
  }

  Future<void> _delete(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> _save(List<SlotSymbol> symbols) async {
    final file = await _metadata;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({
      for (final symbol in symbols)
        symbol.id: {'imagePath': symbol.imagePath, 'soundPath': symbol.soundPath},
    }));
  }
}
