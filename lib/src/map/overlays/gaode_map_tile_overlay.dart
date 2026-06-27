/// URL template for a tile overlay. Use `{x}`, `{y}`, `{z}` placeholders.
class GaodeMapTileOverlay {
  const GaodeMapTileOverlay({
    required this.id,
    required this.urlTemplate,
    this.zIndex = 0,
    this.visible = true,
    this.tileSize = 256,
  });

  final String id;
  final String urlTemplate;
  final int zIndex;
  final bool visible;
  final int tileSize;

  Map<String, dynamic> toMap() => {
    'id': id,
    'urlTemplate': urlTemplate,
    'zIndex': zIndex,
    'visible': visible,
    'tileSize': tileSize,
  };
}
