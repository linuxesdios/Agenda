import 'tarea.dart'; // para generarId()

/// Marcador/bookmark — acceso rápido a un sitio web.
class Marcador {
  String id;
  String nombre;
  String url;
  String icono; // emoji

  Marcador({
    String? id,
    required this.nombre,
    required this.url,
    this.icono = '🔗',
  }) : id = id ?? generarId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'url': url,
        'icono': icono,
      };

  factory Marcador.fromJson(Map<String, dynamic> json) => Marcador(
        id: json['id'] as String? ?? generarId(),
        nombre: json['nombre'] as String? ?? '',
        url: json['url'] as String? ?? '',
        icono: json['icono'] as String? ?? '🔗',
      );
}
