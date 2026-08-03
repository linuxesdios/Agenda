import 'datos_agenda.dart';

/// Envoltorio para los datos que viajan a/desde la nube.
///
/// No sube el archivo .db directamente — sube una "foto" JSON de todo
/// el contenido de la agenda, envuelta con metadatos de sincronización.
///
/// Flujo:
///   SQLite → DatosAgenda → SobreSync.toJson() → String JSON → Nube
///   Nube → String JSON → SobreSync.fromJson() → DatosAgenda → SQLite
class SobreSync {
  /// Versión del esquema del JSON. Si en el futuro cambiamos la estructura
  /// de los datos, incrementamos esto para saber si hay que migrar.
  final int schemaVersion;

  /// Timestamp UTC en milisegundos de la última modificación.
  /// Se usa para resolver conflictos: gana el más reciente.
  final int lastModified;

  /// Nombre del dispositivo que hizo la última subida.
  final String dispositivoOrigen;

  /// Los datos completos de la agenda.
  final DatosAgenda datos;

  SobreSync({
    this.schemaVersion = 1,
    required this.lastModified,
    required this.dispositivoOrigen,
    required this.datos,
  });

  /// Crea un sobre con el timestamp actual.
  factory SobreSync.ahora({
    required DatosAgenda datos,
    required String dispositivoOrigen,
  }) {
    return SobreSync(
      lastModified: DateTime.now().toUtc().millisecondsSinceEpoch,
      dispositivoOrigen: dispositivoOrigen,
      datos: datos,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'lastModified': lastModified,
        'dispositivoOrigen': dispositivoOrigen,
        'datos': datos.toJson(),
      };

  factory SobreSync.fromJson(Map<String, dynamic> json) => SobreSync(
        schemaVersion: json['schemaVersion'] as int? ?? 1,
        lastModified: json['lastModified'] as int? ?? 0,
        dispositivoOrigen: json['dispositivoOrigen'] as String? ?? '',
        datos: DatosAgenda.fromJson(
            json['datos'] as Map<String, dynamic>? ?? {}),
      );

  /// Fecha legible para mostrar al usuario.
  String get fechaLegible {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(lastModified, isUtc: true)
            .toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
