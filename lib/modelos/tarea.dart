import 'dart:math';

/// Genera un ID único combinando timestamp + random.
/// Similar a como lo hace la app web con Date.now() + Math.random().
String generarId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(99999);
  return '$now$random';
}

/// Subtarea dentro de una tarea (tanto críticas como de listas).
class Subtarea {
  String id;
  String texto;
  String estado;
  String? persona;
  String? fechaMigrar;

  Subtarea({
    String? id,
    required this.texto,
    this.estado = 'pendiente',
    this.persona,
    this.fechaMigrar,
  }) : id = id ?? generarId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'estado': estado,
        'persona': persona,
        'fechaMigrar': fechaMigrar,
      };

  factory Subtarea.fromJson(Map<String, dynamic> json) => Subtarea(
        id: json['id'] as String? ?? generarId(),
        texto: json['texto'] as String? ?? '',
        estado: json['estado'] as String? ?? 'pendiente',
        persona: json['persona'] as String?,
        fechaMigrar: json['fechaMigrar'] as String?,
      );
}

/// Tarea unificada: sirve tanto para tareas críticas como para tareas
/// dentro de listas personalizadas.
///
/// En la app web, las tareas críticas usan "titulo"/"fecha_fin" y las de
/// listas usan "texto"/"fecha". Aquí unificamos con fromJson que acepta
/// ambos formatos.
class Tarea {
  String id;
  String titulo;

  /// Formato: 'YYYY-MM-DD' (solo fecha) o 'YYYY-MM-DDTHH:MM' (fecha+hora).
  String? fechaLimite;
  String? etiqueta;

  /// Estados Bullet Journal:
  ///   'pendiente'   ●  Tarea por hacer
  ///   'completada'  ✕  Tarea completada
  ///   'migrada'     >  Migrada/delegada a persona
  ///   'programada'  <  Programada para fecha futura
  ///   'importante'  *  Prioridad / importante
  ///   'idea'        !  Idea / inspiración
  ///   'investigar'  ?  Investigar / buscar
  String estado;
  String? persona;
  String? fechaMigrar;
  List<Subtarea> subtareas;
  String fechaCreacion;
  String? fechaCompletada;

  Tarea({
    String? id,
    required this.titulo,
    this.fechaLimite,
    this.etiqueta,
    this.estado = 'pendiente',
    this.persona,
    this.fechaMigrar,
    List<Subtarea>? subtareas,
    String? fechaCreacion,
    this.fechaCompletada,
  })  : id = id ?? generarId(),
        subtareas = subtareas ?? [],
        fechaCreacion = fechaCreacion ?? DateTime.now().toIso8601String();

  bool get completada => estado == 'completada';

  /// Devuelve solo la parte de fecha ('YYYY-MM-DD') si existe.
  String? get soloFecha {
    if (fechaLimite == null) return null;
    return fechaLimite!.contains('T')
        ? fechaLimite!.split('T')[0]
        : fechaLimite;
  }

  /// Devuelve solo la parte de hora ('HH:MM') si existe.
  String? get soloHora {
    if (fechaLimite == null || !fechaLimite!.contains('T')) return null;
    return fechaLimite!.split('T')[1].substring(0, 5);
  }

  /// Comprueba si la fecha límite es hoy.
  bool get esHoy {
    final fecha = soloFecha;
    if (fecha == null) return false;
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    return fecha == hoyStr;
  }

  /// Comprueba si la fecha límite ya pasó.
  bool get esPasada {
    final fecha = soloFecha;
    if (fecha == null) return false;
    final partes = fecha.split('-');
    if (partes.length != 3) return false;
    final fechaObj = DateTime(
        int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
    final hoy = DateTime.now();
    final hoyLimpio = DateTime(hoy.year, hoy.month, hoy.day);
    return fechaObj.isBefore(hoyLimpio);
  }

  /// Formatea la fecha para mostrar: 'dd/mm/yyyy' o 'dd/mm/yyyy HH:MM'.
  String get fechaFormateada {
    if (fechaLimite == null) return '';
    final fecha = soloFecha!;
    final partes = fecha.split('-');
    if (partes.length != 3) return fechaLimite!;
    final resultado = '${partes[2]}/${partes[1]}/${partes[0]}';
    final hora = soloHora;
    if (hora != null) return '$resultado $hora';
    return resultado;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'fechaLimite': fechaLimite,
        'etiqueta': etiqueta,
        'estado': estado,
        'persona': persona,
        'fechaMigrar': fechaMigrar,
        'subtareas': subtareas.map((s) => s.toJson()).toList(),
        'fechaCreacion': fechaCreacion,
        'fechaCompletada': fechaCompletada,
      };

  /// Acepta tanto el formato Flutter como el de la app web
  /// (titulo/texto, fechaLimite/fecha_fin/fecha, etc.)
  factory Tarea.fromJson(Map<String, dynamic> json) => Tarea(
        id: json['id'] as String? ?? generarId(),
        titulo:
            (json['titulo'] ?? json['texto'] ?? 'Sin título') as String,
        fechaLimite: (json['fechaLimite'] ??
            json['fecha_fin'] ??
            json['fecha']) as String?,
        etiqueta: json['etiqueta'] as String?,
        estado: json['estado'] as String? ?? 'pendiente',
        persona: json['persona'] as String?,
        fechaMigrar:
            (json['fechaMigrar'] ?? json['fecha_migrar']) as String?,
        subtareas: (json['subtareas'] as List<dynamic>?)
                ?.map((s) => Subtarea.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        fechaCreacion: json['fechaCreacion'] as String?,
        fechaCompletada:
            (json['fechaCompletada'] ?? json['fecha_completada'])
                as String?,
      );
}
