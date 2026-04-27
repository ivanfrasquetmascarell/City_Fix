enum TipoMedia { IMAGEN, VIDEO }

class Multimedia {
  final int id;
  String url;
  final TipoMedia tipo;

  Multimedia({
    required this.id,
    required this.url,
    required this.tipo,
  });

  factory Multimedia.fromJson(Map<String, dynamic> json) {
    try {
      return Multimedia(
        id: json['id'] as int? ?? 0,
        url: json['url']?.toString() ?? '',
        tipo: (json['tipo']?.toString() == 'VIDEO') ? TipoMedia.VIDEO : TipoMedia.IMAGEN,
      );
    } catch (e) {
      return Multimedia(id: 0, url: '', tipo: TipoMedia.IMAGEN);
    }
  }
}
