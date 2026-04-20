enum TipoMedia { IMAGEN, VIDEO }

class Multimedia {
  final int id;
  final String url;
  final TipoMedia tipo;

  Multimedia({
    required this.id,
    required this.url,
    required this.tipo,
  });

  factory Multimedia.fromJson(Map<String, dynamic> json) {
    return Multimedia(
      id: json['id'],
      url: json['url'],
      tipo: json['tipo'] == 'VIDEO' ? TipoMedia.VIDEO : TipoMedia.IMAGEN,
    );
  }
}
