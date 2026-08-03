import 'tarea.dart';

/// Lista personalizada de tareas (ej: "Médico", "Compras", "Trabajo").
/// Equivale a las listas personalizadas de la app web.
class ListaPersonalizada {
  String id;
  String nombre;
  String emoji;

  /// Color en formato hex, ej: '#667eea'.
  String color;
  List<Tarea> tareas;
  int orden;
  bool esListaPorDefecto;
  String fechaCreacion;

  ListaPersonalizada({
    String? id,
    required this.nombre,
    this.emoji = '📋',
    this.color = '#4ecdc4',
    List<Tarea>? tareas,
    this.orden = 0,
    this.esListaPorDefecto = false,
    String? fechaCreacion,
  })  : id = id ?? 'lista-${generarId()}',
        tareas = tareas ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'emoji': emoji,
        'color': color,
        'tareas': tareas.map((t) => t.toJson()).toList(),
        'orden': orden,
        'esListaPorDefecto': esListaPorDefecto,
        'fechaCreacion': fechaCreacion,
      };

  factory ListaPersonalizada.fromJson(Map<String, dynamic> json) =>
      ListaPersonalizada(
        id: json['id'] as String? ?? 'lista-${generarId()}',
        nombre: json['nombre'] as String? ?? 'Sin nombre',
        emoji: json['emoji'] as String? ?? '📋',
        color: json['color'] as String? ?? '#4ecdc4',
        tareas: (json['tareas'] as List<dynamic>?)
                ?.map((t) => Tarea.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        orden: json['orden'] as int? ?? 0,
        esListaPorDefecto: json['esListaPorDefecto'] as bool? ?? false,
        fechaCreacion: json['fechaCreacion'] as String?,
      );
}
