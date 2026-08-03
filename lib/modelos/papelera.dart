import 'tarea.dart';

/// Elemento eliminado guardado en la papelera durante 30 días.
class ElementoPapelera {
  final String id;
  final String tipo; // 'tarea_critica', 'tarea_lista', 'cita'
  final String titulo;
  final String fechaEliminado;
  final Map<String, dynamic> datosJson;

  ElementoPapelera({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.fechaEliminado,
    required this.datosJson,
  });

  bool get expirado {
    final eliminado = DateTime.tryParse(fechaEliminado);
    if (eliminado == null) return true;
    return DateTime.now().difference(eliminado).inDays > 30;
  }

  String get fechaLegible {
    final p = fechaEliminado.split('T')[0].split('-');
    if (p.length != 3) return fechaEliminado;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  int get diasRestantes {
    final eliminado = DateTime.tryParse(fechaEliminado);
    if (eliminado == null) return 0;
    return 30 - DateTime.now().difference(eliminado).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'titulo': titulo,
        'fechaEliminado': fechaEliminado,
        'datosJson': datosJson,
      };

  factory ElementoPapelera.fromJson(Map<String, dynamic> json) =>
      ElementoPapelera(
        id: json['id'] as String? ?? generarId(),
        tipo: json['tipo'] as String? ?? '',
        titulo: json['titulo'] as String? ?? '',
        fechaEliminado: json['fechaEliminado'] as String? ?? '',
        datosJson: Map<String, dynamic>.from(
            json['datosJson'] as Map? ?? {}),
      );
}
