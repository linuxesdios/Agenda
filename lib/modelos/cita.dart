import 'tarea.dart'; // para generarId()

/// Cita/evento del calendario.
class Cita {
  String id;
  String fecha; // 'YYYY-MM-DD'
  String hora;  // 'HH:MM' (ej: '14:30')
  String descripcion;
  String? etiqueta;

  /// Minutos antes para notificar (puede ser múltiple).
  /// Ej: [15, 60, 1440] = 15 min, 1 hora, 1 día antes.
  List<int> recordatorios;

  Cita({
    String? id,
    required this.fecha,
    required this.hora,
    required this.descripcion,
    this.etiqueta,
    List<int>? recordatorios,
  })  : id = id ?? generarId(),
        recordatorios = recordatorios ?? [15];

  DateTime get fechaHora {
    final p = fecha.split('-');
    final hm = hora.split(':');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]),
        int.parse(hm[0]), int.parse(hm[1]));
  }

  String get fechaFormateada {
    final p = fecha.split('-');
    return '${p[2]}/${p[1]}/${p[0]} $hora';
  }

  /// True si la cita ya pasó (fecha+hora < ahora).
  bool get haPasado => fechaHora.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        'hora': hora,
        'descripcion': descripcion,
        'etiqueta': etiqueta,
        'recordatorios': recordatorios,
      };

  factory Cita.fromJson(Map<String, dynamic> json) => Cita(
        id: json['id'] as String? ?? generarId(),
        fecha: json['fecha'] as String? ?? '',
        hora: json['hora'] as String? ?? '12:00',
        descripcion:
            (json['descripcion'] ?? json['desc']) as String? ?? '',
        etiqueta: json['etiqueta'] as String?,
        recordatorios: (json['recordatorios'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [15],
      );
}
