import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../modelos/datos_agenda.dart';
import 'almacenamiento_repository.dart';

/// Implementación de AlmacenamientoRepository que guarda todo en un
/// único archivo JSON en disco.
///
/// Soporta una ruta de sincronización configurable: si el usuario
/// la establece (ej: carpeta de OneDrive/Syncthing), el archivo se
/// guarda TAMBIÉN ahí para sincronizar entre dispositivos.
///
/// El archivo siempre se guarda en la ubicación local por defecto.
/// Si hay ruta de sync, se guarda en ambas, y al cargar se usa
/// la versión más reciente.
class AlmacenamientoArchivoJson implements AlmacenamientoRepository {
  static const _nombreArchivo = 'agenda_datos.json';

  /// Ruta de sincronización configurada por el usuario.
  /// Se actualiza desde AgendaEstado cuando el usuario la cambia.
  String? rutaSincronizacion;

  Future<File> _archivoLocal() async {
    final directorio = await getApplicationDocumentsDirectory();
    return File('${directorio.path}/$_nombreArchivo');
  }

  File? _archivoSync() {
    if (rutaSincronizacion == null || rutaSincronizacion!.isEmpty) return null;
    return File('$rutaSincronizacion/$_nombreArchivo');
  }

  /// Lee un archivo JSON y devuelve DatosAgenda, o null si falla.
  Future<DatosAgenda?> _leerArchivo(File archivo) async {
    try {
      if (!await archivo.exists()) return null;
      final contenido = await archivo.readAsString();
      if (contenido.isEmpty) return null;
      final json = jsonDecode(contenido) as Map<String, dynamic>;
      return DatosAgenda.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DatosAgenda> cargarTodo() async {
    final local = await _archivoLocal();
    final sync = _archivoSync();

    final datosLocal = await _leerArchivo(local);

    // Si hay carpeta de sync, comparar timestamps y usar el más reciente
    if (sync != null) {
      final datosSync = await _leerArchivo(sync);
      if (datosLocal == null && datosSync != null) return datosSync;
      if (datosLocal != null && datosSync == null) return datosLocal;
      if (datosLocal != null && datosSync != null) {
        // Usar el archivo modificado más recientemente
        final tsLocal = await local.lastModified();
        final tsSync = await sync.lastModified();
        return tsSync.isAfter(tsLocal) ? datosSync : datosLocal;
      }
    }

    return datosLocal ?? DatosAgenda();
  }

  @override
  Future<void> guardarTodo(DatosAgenda datos) async {
    final json = jsonEncode(datos.toJson());

    // Siempre guardar en local
    final local = await _archivoLocal();
    await local.writeAsString(json, flush: true);

    // Si hay ruta de sync, guardar también ahí
    final sync = _archivoSync();
    if (sync != null) {
      try {
        final dir = sync.parent;
        if (!await dir.exists()) await dir.create(recursive: true);
        await sync.writeAsString(json, flush: true);
      } catch (_) {
        // Si la carpeta de sync no es accesible, no bloquear la app
      }
    }
  }
}
