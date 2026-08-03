import '../modelos/datos_agenda.dart';

/// Interfaz abstracta para la persistencia de datos.
///
/// En MVVM esto equivale a la interfaz del repositorio. La ventaja
/// es que puedes cambiar la implementación (archivo local, SQLite,
/// servidor remoto) sin tocar el resto de la app.
///
/// Implementación actual: AlmacenamientoArchivoJson (archivo JSON local).
/// Futuro: podrías añadir AlmacenamientoRemoto para sincronización.
abstract class AlmacenamientoRepository {
  /// Carga todos los datos de la agenda.
  /// Devuelve un DatosAgenda vacío si no hay datos previos.
  Future<DatosAgenda> cargarTodo();

  /// Guarda todos los datos de la agenda.
  Future<void> guardarTodo(DatosAgenda datos);
}
