class SlotSymbol {
  const SlotSymbol({
    required this.id,
    required this.imagePath,
    this.soundPath,
  });

  final String id;
  final String? imagePath;
  final String? soundPath;

  SlotSymbol copyWith({String? imagePath, String? soundPath, bool clearSound = false}) =>
      SlotSymbol(
        id: id,
        imagePath: imagePath ?? this.imagePath,
        soundPath: clearSound ? null : (soundPath ?? this.soundPath),
      );
}
