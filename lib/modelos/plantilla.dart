import 'tarea.dart';

/// Plantilla reutilizable para crear tareas con subtareas predefinidas.
class PlantillaTarea {
  String id;
  String nombre;
  List<String> subtareasTexto;
  String? etiqueta;

  PlantillaTarea({
    String? id,
    required this.nombre,
    List<String>? subtareasTexto,
    this.etiqueta,
  })  : id = id ?? generarId(),
        subtareasTexto = subtareasTexto ?? [];

  Tarea generarTarea() {
    return Tarea(
      titulo: nombre,
      etiqueta: etiqueta,
      subtareas: subtareasTexto
          .map((texto) => Subtarea(texto: texto))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'subtareasTexto': subtareasTexto,
        'etiqueta': etiqueta,
      };

  factory PlantillaTarea.fromJson(Map<String, dynamic> json) =>
      PlantillaTarea(
        id: json['id'] as String? ?? generarId(),
        nombre: json['nombre'] as String? ?? '',
        subtareasTexto: (json['subtareasTexto'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        etiqueta: json['etiqueta'] as String?,
      );
}
