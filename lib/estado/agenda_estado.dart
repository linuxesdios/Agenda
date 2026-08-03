import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../modelos/tarea.dart';
import '../modelos/lista_personalizada.dart';
import '../modelos/etiqueta.dart';
import '../modelos/configuracion.dart';
import '../modelos/cita.dart';
import '../modelos/contrasena.dart';
import '../modelos/marcador.dart';
import '../modelos/datos_agenda.dart';
import '../modelos/papelera.dart';
import '../modelos/plantilla.dart';
import '../repositorios/almacenamiento_repository.dart';
import '../repositorios/almacenamiento_sqlite.dart';
import '../servicios/cliente_nube.dart';
import '../servicios/servicio_notificaciones.dart';
import '../servicios/servicio_widget.dart';
import '../modelos/sobre_sync.dart';
import '../i18n/idioma.dart';
import '../i18n/traducciones.dart';

/// Estado de la sincronización con la nube.
enum EstadoSync { sincronizado, subiendo, pendiente, sinConexion, error, desactivado }

/// Estado central de la agenda — equivale al ViewModel en MVVM.
///
/// Cada método que modifica datos:
///   1. Modifica el estado en memoria
///   2. notifyListeners() → la UI se actualiza
///   3. _guardar() → SQLite local (instantáneo, funciona offline)
///   4. _sincronizar() → sube a la nube en segundo plano
///      - inmediato: true → sube ya (crear, borrar)
///      - inmediato: false → espera 3s de debounce (editar, notas)
class AgendaEstado extends ChangeNotifier {
  final AlmacenamientoRepository _repositorio;
  final DatosAgenda _datos;

  EstadoSync estadoSync = EstadoSync.desactivado;
  DateTime? ultimaSync;
  Timer? _debounceTimer;
  Timer? _syncPeriodicoTimer;
  bool _syncEnCurso = false;

  AgendaEstado({
    required this._repositorio,
    required DatosAgenda datosIniciales,
  }) : _datos = datosIniciales {
    _iniciarSyncPeriodico();
  }

  bool _hayCambiosLocales = false;

  void _iniciarSyncPeriodico() {
    _syncPeriodicoTimer?.cancel();
    _syncPeriodicoTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        if (_hayCambiosLocales) _ejecutarSync();
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _syncPeriodicoTimer?.cancel();
    super.dispose();
  }

  String get ultimaSyncTexto {
    if (ultimaSync == null) return t('principal.nunca');
    final diff = DateTime.now().difference(ultimaSync!);
    if (diff.inSeconds < 60) {
      return t('principal.hace_segundos').replaceAll('{n}', '${diff.inSeconds}');
    }
    if (diff.inMinutes < 60) {
      return t('principal.hace_minutos').replaceAll('{n}', '${diff.inMinutes}');
    }
    return t('principal.hace_horas').replaceAll('{n}', '${diff.inHours}');
  }

  // ═══════════════════════════════════════════
  // GETTERS — los widgets leen de aquí
  // ═══════════════════════════════════════════

  List<Tarea> get tareasCriticas => _datos.tareasCriticas;
  List<ListaPersonalizada> get listasPersonalizadas =>
      _datos.listasPersonalizadas;
  List<Etiqueta> get etiquetas => _datos.etiquetas;
  List<Etiqueta> get etiquetasTareas =>
      _datos.etiquetas.where((e) => e.tipo == 'tareas').toList();
  List<Etiqueta> get etiquetasCitas =>
      _datos.etiquetas.where((e) => e.tipo == 'citas').toList();
  List<Cita> get citas => _datos.citas;

  /// Citas de hoy en adelante, ordenadas por fecha+hora.
  List<Cita> get citasProximas {
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    return _datos.citas
        .where((c) => c.fecha.compareTo(hoyStr) >= 0)
        .toList()
      ..sort((a, b) {
        final cmp = a.fecha.compareTo(b.fecha);
        return cmp != 0 ? cmp : a.hora.compareTo(b.hora);
      });
  }
  List<String> get personas => _datos.personas;
  List<Contrasena> get contrasenas => _datos.contrasenas;
  List<Marcador> get marcadores => _datos.marcadores;
  String get notas => _datos.notas;
  String get sentimientos => _datos.sentimientos;
  List<ElementoPapelera> get papelera => _datos.papelera;
  List<PlantillaTarea> get plantillas => _datos.plantillas;
  Configuracion get configuracion => _datos.configuracion;
  bool get modoOscuro => _datos.configuracion.modoOscuro;
  String get titulo => _datos.configuracion.titulo;
  String get dispositivoNombre => _datos.configuracion.dispositivoNombre;
  String get paleta => _datos.configuracion.paleta;
  int get columnas => _datos.configuracion.columnas;
  String get distribucion => _datos.configuracion.distribucion;
  double get tamanoLetra => _datos.configuracion.tamanoLetra;
  String get iconoApp => _datos.configuracion.iconoApp;
  String get frases => _datos.configuracion.frases;

  /// Idioma activo de la interfaz. Si la configuración no tiene uno guardado
  /// (primer arranque), se detecta del sistema operativo.
  Idioma get idioma =>
      idiomaDesdeCodigo(_datos.configuracion.idioma) ??
      detectarIdiomaDelSistema();

  /// Traduce una clave al idioma activo. Ej: `estado.t('comun.guardar')`.
  String t(String clave) => Traducciones.t(idioma, clave);
  bool get widgetMostrarCriticas => _datos.configuracion.widgetMostrarCriticas;
  bool get widgetMostrarCitas => _datos.configuracion.widgetMostrarCitas;
  bool get widgetMostrarHoy => _datos.configuracion.widgetMostrarHoy;
  bool get widgetMostrarListas => _datos.configuracion.widgetMostrarListas;

  // ═══════════════════════════════════════════
  // PERSISTENCIA + SYNC AUTOMÁTICA
  // ═══════════════════════════════════════════

  /// Guarda en SQLite y programa subida a la nube.
  /// [inmediato] = true para crear/borrar, false para ediciones menores.
  Future<void> _guardar({bool inmediato = false}) async {
    _hayCambiosLocales = true;
    await _repositorio.guardarTodo(_datos);
    _sincronizar(inmediato: inmediato);
    // Refrescar el widget de Android con los datos nuevos (fire-and-forget)
    ServicioWidget.actualizar(this);
  }

  /// Sube a la nube en segundo plano. No bloquea la UI.
  /// Con debounce de 3s para ediciones, inmediato para crear/borrar.
  void _sincronizar({bool inmediato = false}) {
    _debounceTimer?.cancel();
    if (inmediato) {
      _ejecutarSync();
    } else {
      estadoSync = EstadoSync.pendiente;
      notifyListeners();
      _debounceTimer = Timer(const Duration(seconds: 3), _ejecutarSync);
    }
  }

  Future<void> _ejecutarSync() async {
    if (_syncEnCurso) return;
    if (_repositorio is! AlmacenamientoSqlite) return;

    // Leer credenciales
    final cred = await ClienteNube.leerCredenciales();
    if (cred.token == null || cred.gistId == null ||
        cred.token!.isEmpty || cred.gistId!.isEmpty) {
      estadoSync = EstadoSync.desactivado;
      notifyListeners();
      return;
    }

    _syncEnCurso = true;
    estadoSync = EstadoSync.subiendo;
    notifyListeners();

    try {
      final json = await _repositorio.exportarAJson();
      final cliente = ClienteNube(token: cred.token!, gistId: cred.gistId!);
      await cliente.subir(json);
      estadoSync = EstadoSync.sincronizado;
      ultimaSync = DateTime.now();
      _hayCambiosLocales = false;
    } catch (_) {
      estadoSync = EstadoSync.error;
    } finally {
      _syncEnCurso = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════
  // TAREAS CRÍTICAS
  // ═══════════════════════════════════════════

  Future<void> agregarTareaCritica(Tarea tarea) async {
    _datos.tareasCriticas.add(tarea);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> editarTareaCritica(int index, Tarea tarea) async {
    if (index < 0 || index >= _datos.tareasCriticas.length) return;
    _datos.tareasCriticas[index] = tarea;
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarTareaCritica(int index) async {
    if (index < 0 || index >= _datos.tareasCriticas.length) return;
    final tarea = _datos.tareasCriticas.removeAt(index);
    _datos.papelera.add(ElementoPapelera(
      id: tarea.id, tipo: 'tarea_critica', titulo: tarea.titulo,
      fechaEliminado: DateTime.now().toIso8601String(),
      datosJson: tarea.toJson(),
    ));
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> cambiarEstadoTareaCritica(int index, String nuevoEstado) async {
    if (index < 0 || index >= _datos.tareasCriticas.length) return;
    final tarea = _datos.tareasCriticas[index];
    tarea.estado = nuevoEstado;
    if (nuevoEstado == 'completada') {
      tarea.fechaCompletada = DateTime.now().toIso8601String();
    } else {
      tarea.fechaCompletada = null;
    }
    notifyListeners();
    await _guardar();
  }

  /// Cambia estado de tarea crítica con datos opcionales (persona, fecha).
  Future<void> cambiarEstadoCriticaConDatos(
      int index, String nuevoEstado,
      {String? persona, String? fecha}) async {
    if (index < 0 || index >= _datos.tareasCriticas.length) return;
    final tarea = _datos.tareasCriticas[index];
    tarea.estado = nuevoEstado;
    if (persona != null) tarea.persona = persona.isEmpty ? null : persona;
    if (fecha != null) tarea.fechaLimite = fecha.isEmpty ? null : fecha;
    if (nuevoEstado == 'completada') {
      tarea.fechaCompletada = DateTime.now().toIso8601String();
    } else {
      tarea.fechaCompletada = null;
    }
    notifyListeners();
    await _guardar(inmediato: true);
  }

  /// Agrega una subtarea a una tarea crítica.
  Future<void> agregarSubtareaCritica(int tareaIndex, Subtarea sub) async {
    if (tareaIndex < 0 || tareaIndex >= _datos.tareasCriticas.length) return;
    _datos.tareasCriticas[tareaIndex].subtareas.add(sub);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> eliminarSubtareaCritica(int tareaIndex, int subIndex) async {
    if (tareaIndex < 0 || tareaIndex >= _datos.tareasCriticas.length) return;
    final subs = _datos.tareasCriticas[tareaIndex].subtareas;
    if (subIndex < 0 || subIndex >= subs.length) return;
    subs.removeAt(subIndex);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> cambiarEstadoSubtareaCritica(
      int tareaIndex, int subIndex, String nuevoEstado) async {
    if (tareaIndex < 0 || tareaIndex >= _datos.tareasCriticas.length) return;
    final subs = _datos.tareasCriticas[tareaIndex].subtareas;
    if (subIndex < 0 || subIndex >= subs.length) return;
    subs[subIndex].estado = nuevoEstado;
    notifyListeners();
    await _guardar();
  }

  // ═══════════════════════════════════════════
  // LISTAS PERSONALIZADAS
  // ═══════════════════════════════════════════

  Future<void> agregarLista(ListaPersonalizada lista) async {
    _datos.listasPersonalizadas.add(lista);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> editarLista(String listaId, ListaPersonalizada lista) async {
    final index =
        _datos.listasPersonalizadas.indexWhere((l) => l.id == listaId);
    if (index == -1) return;
    _datos.listasPersonalizadas[index] = lista;
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarLista(String listaId) async {
    _datos.listasPersonalizadas.removeWhere((l) => l.id == listaId);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> moverLista(int fromIndex, int toIndex) async {
    if (fromIndex < 0 || fromIndex >= _datos.listasPersonalizadas.length) return;
    if (toIndex < 0 || toIndex >= _datos.listasPersonalizadas.length) return;
    final lista = _datos.listasPersonalizadas.removeAt(fromIndex);
    _datos.listasPersonalizadas.insert(toIndex, lista);
    notifyListeners();
    await _guardar();
  }

  /// Mueve una tarea de una lista personalizada a tareas críticas.
  Future<void> moverACriticas(String listaId, int index) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || index < 0 || index >= lista.tareas.length) return;
    final tarea = lista.tareas.removeAt(index);
    tarea.estado = 'importante';
    _datos.tareasCriticas.add(tarea);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  /// Agrega una tarea a una lista personalizada.
  Future<void> agregarTareaALista(String listaId, Tarea tarea) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null) return;
    lista.tareas.add(tarea);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> editarTareaDeLista(
      String listaId, int index, Tarea tarea) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || index < 0 || index >= lista.tareas.length) return;
    lista.tareas[index] = tarea;
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarTareaDeLista(String listaId, int index) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || index < 0 || index >= lista.tareas.length) return;
    final tarea = lista.tareas.removeAt(index);
    _datos.papelera.add(ElementoPapelera(
      id: tarea.id, tipo: 'tarea_lista', titulo: tarea.titulo,
      fechaEliminado: DateTime.now().toIso8601String(),
      datosJson: {...tarea.toJson(), '_listaId': listaId},
    ));
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> cambiarEstadoTareaDeLista(
      String listaId, int index, String nuevoEstado) async {
    cambiarEstadoListaConDatos(listaId, index, nuevoEstado);
  }

  Future<void> cambiarEstadoListaConDatos(
      String listaId, int index, String nuevoEstado,
      {String? persona, String? fecha}) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || index < 0 || index >= lista.tareas.length) return;
    final tarea = lista.tareas[index];
    tarea.estado = nuevoEstado;
    if (persona != null) tarea.persona = persona.isEmpty ? null : persona;
    if (fecha != null) tarea.fechaLimite = fecha.isEmpty ? null : fecha;
    if (nuevoEstado == 'completada') {
      tarea.fechaCompletada = DateTime.now().toIso8601String();
    } else {
      tarea.fechaCompletada = null;
    }
    notifyListeners();
    await _guardar();
  }

  Future<void> agregarSubtareaALista(
      String listaId, int tareaIndex, Subtarea sub) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || tareaIndex < 0 || tareaIndex >= lista.tareas.length) {
      return;
    }
    lista.tareas[tareaIndex].subtareas.add(sub);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> eliminarSubtareaDeLista(
      String listaId, int tareaIndex, int subIndex) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || tareaIndex < 0 || tareaIndex >= lista.tareas.length) {
      return;
    }
    final subs = lista.tareas[tareaIndex].subtareas;
    if (subIndex < 0 || subIndex >= subs.length) return;
    subs.removeAt(subIndex);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> cambiarEstadoSubtareaDeLista(
      String listaId, int tareaIndex, int subIndex, String nuevoEstado) async {
    final lista =
        _datos.listasPersonalizadas.where((l) => l.id == listaId).firstOrNull;
    if (lista == null || tareaIndex < 0 || tareaIndex >= lista.tareas.length) {
      return;
    }
    final subs = lista.tareas[tareaIndex].subtareas;
    if (subIndex < 0 || subIndex >= subs.length) return;
    subs[subIndex].estado = nuevoEstado;
    notifyListeners();
    await _guardar();
  }

  // ═══════════════════════════════════════════
  // ETIQUETAS
  // ═══════════════════════════════════════════

  Future<void> agregarEtiqueta(Etiqueta etiqueta) async {
    _datos.etiquetas.add(etiqueta);
    notifyListeners();
    await _guardar();
  }

  Future<void> editarEtiqueta(int index, Etiqueta etiqueta) async {
    if (index < 0 || index >= _datos.etiquetas.length) return;
    _datos.etiquetas[index] = etiqueta;
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarEtiqueta(int index) async {
    if (index < 0 || index >= _datos.etiquetas.length) return;
    _datos.etiquetas.removeAt(index);
    notifyListeners();
    await _guardar();
  }

  /// Busca una etiqueta por nombre para mostrar su emoji y color.
  Etiqueta? buscarEtiqueta(String? nombre) {
    if (nombre == null || nombre.isEmpty) return null;
    return _datos.etiquetas.where((e) => e.nombre == nombre).firstOrNull;
  }

  // ═══════════════════════════════════════════
  // PERSONAS
  // ═══════════════════════════════════════════

  Future<void> agregarPersona(String nombre) async {
    if (nombre.trim().isEmpty) return;
    if (_datos.personas.contains(nombre.trim())) return;
    _datos.personas.add(nombre.trim());
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarPersona(int index) async {
    if (index < 0 || index >= _datos.personas.length) return;
    _datos.personas.removeAt(index);
    notifyListeners();
    await _guardar();
  }

  // ═══════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════

  Future<void> cambiarModoOscuro(bool valor) async {
    _datos.configuracion.modoOscuro = valor;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarTitulo(String titulo) async {
    _datos.configuracion.titulo = titulo;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarPaleta(String paleta) async {
    _datos.configuracion.paleta = paleta;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarColumnas(int columnas) async {
    _datos.configuracion.columnas = columnas.clamp(1, 3);
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarTamanoLetra(double tamano) async {
    _datos.configuracion.tamanoLetra = tamano.clamp(10, 24);
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarIconoApp(String icono) async {
    _datos.configuracion.iconoApp = icono;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarFrases(String frases) async {
    _datos.configuracion.frases = frases;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarIdioma(Idioma nuevoIdioma) async {
    _datos.configuracion.idioma = nuevoIdioma.codigo;
    notifyListeners();
    await _guardar();
  }

  /// Si todavía no hay un idioma guardado (primer arranque), detecta el del
  /// sistema y lo persiste. Se llama una vez al iniciar la app.
  Future<void> asegurarIdiomaDetectado() async {
    if (_datos.configuracion.idioma != null) return;
    _datos.configuracion.idioma = detectarIdiomaDelSistema().codigo;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarResumenDiario(bool valor) async {
    _datos.configuracion.resumenDiario = valor;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarWidgetMostrarCriticas(bool valor) async {
    _datos.configuracion.widgetMostrarCriticas = valor;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarWidgetMostrarCitas(bool valor) async {
    _datos.configuracion.widgetMostrarCitas = valor;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarWidgetMostrarHoy(bool valor) async {
    _datos.configuracion.widgetMostrarHoy = valor;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarWidgetMostrarListas(bool valor) async {
    _datos.configuracion.widgetMostrarListas = valor;
    notifyListeners();
    await _guardar();
  }

  Future<void> cambiarRecordatoriosPorDefecto(List<int> valores) async {
    _datos.configuracion.recordatoriosPorDefecto = valores;
    notifyListeners();
    await _guardar();
  }

  /// Borra todas las citas cuya fecha+hora ya pasó.
  Future<int> borrarCitasPasadas() async {
    final pasadas = _datos.citas.where((c) => c.haPasado).toList();
    for (final c in pasadas) {
      ServicioNotificaciones.cancelarRecordatorio(c);
      _datos.papelera.add(ElementoPapelera(
        id: c.id, tipo: 'cita', titulo: c.descripcion,
        fechaEliminado: DateTime.now().toIso8601String(),
        datosJson: c.toJson(),
      ));
    }
    _datos.citas.removeWhere((c) => c.haPasado);
    if (pasadas.isNotEmpty) {
      notifyListeners();
      await _guardar(inmediato: true);
    }
    return pasadas.length;
  }

  /// Devuelve un resumen de los próximos 7 días: citas + tareas con fecha.
  Map<String, ({List<Cita> citas, List<Tarea> tareas})> resumenProxima7Dias() {
    final resultado = <String, ({List<Cita> citas, List<Tarea> tareas})>{};
    final ahora = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final dia = ahora.add(Duration(days: i));
      final fechaStr =
          '${dia.year}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
      final citas = citasDelDia(fechaStr);
      final tareas = tareasDelDia(fechaStr);
      if (citas.isNotEmpty || tareas.isNotEmpty) {
        resultado[fechaStr] = (citas: citas, tareas: tareas);
      }
    }
    return resultado;
  }

  Future<void> cambiarDistribucion(String distribucion) async {
    _datos.configuracion.distribucion = distribucion;
    notifyListeners();
    await _guardar();
  }

  /// Cambia la ruta de la base de datos (para sincronizar via carpeta compartida).
  /// Guarda la ruta en un archivo local y actualiza el repositorio.
  Future<void> cambiarRutaDb(String? ruta) async {
    await AlmacenamientoSqlite.guardarRutaLocal(ruta);
    if (_repositorio is AlmacenamientoSqlite) {
      _repositorio.rutaDb = ruta;
    }
    await _guardar();
    notifyListeners();
  }

  Future<void> cambiarDispositivoNombre(String nombre) async {
    _datos.configuracion.dispositivoNombre = nombre;
    notifyListeners();
    await _guardar();
  }

  // ═══════════════════════════════════════════
  // CITAS
  // ═══════════════════════════════════════════

  Future<void> agregarCita(Cita cita) async {
    _datos.citas.add(cita);
    ServicioNotificaciones.programarRecordatorio(cita);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> editarCita(int index, Cita cita) async {
    if (index < 0 || index >= _datos.citas.length) return;
    ServicioNotificaciones.cancelarRecordatorio(_datos.citas[index]);
    _datos.citas[index] = cita;
    ServicioNotificaciones.programarRecordatorio(cita);
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarCita(int index) async {
    if (index < 0 || index >= _datos.citas.length) return;
    final cita = _datos.citas.removeAt(index);
    ServicioNotificaciones.cancelarRecordatorio(cita);
    _datos.papelera.add(ElementoPapelera(
      id: cita.id, tipo: 'cita', titulo: cita.descripcion,
      fechaEliminado: DateTime.now().toIso8601String(),
      datosJson: cita.toJson(),
    ));
    notifyListeners();
    await _guardar(inmediato: true);
  }

  /// Devuelve las citas de un día concreto (formato 'YYYY-MM-DD').
  List<Cita> citasDelDia(String fecha) {
    return _datos.citas.where((c) => c.fecha == fecha).toList()
      ..sort((a, b) => a.hora.compareTo(b.hora));
  }

  /// Devuelve las tareas (críticas + de listas) que vencen un día concreto.
  List<Tarea> tareasDelDia(String fecha) {
    final resultado = <Tarea>[];
    for (final t in _datos.tareasCriticas) {
      if (t.soloFecha == fecha) resultado.add(t);
    }
    for (final lista in _datos.listasPersonalizadas) {
      for (final t in lista.tareas) {
        if (t.soloFecha == fecha) resultado.add(t);
      }
    }
    return resultado;
  }

  /// Devuelve los días de un mes que tienen citas o tareas.
  Set<int> diasConEventos(int anio, int mes) {
    final dias = <int>{};
    final prefijo =
        '$anio-${mes.toString().padLeft(2, '0')}';
    for (final c in _datos.citas) {
      if (c.fecha.startsWith(prefijo)) {
        dias.add(int.parse(c.fecha.split('-')[2]));
      }
    }
    for (final t in _datos.tareasCriticas) {
      final f = t.soloFecha;
      if (f != null && f.startsWith(prefijo)) {
        dias.add(int.parse(f.split('-')[2]));
      }
    }
    for (final lista in _datos.listasPersonalizadas) {
      for (final t in lista.tareas) {
        final f = t.soloFecha;
        if (f != null && f.startsWith(prefijo)) {
          dias.add(int.parse(f.split('-')[2]));
        }
      }
    }
    return dias;
  }

  // ═══════════════════════════════════════════
  // NOTAS Y SENTIMIENTOS
  // ═══════════════════════════════════════════

  Future<void> guardarNotas(String texto) async {
    _datos.notas = texto;
    notifyListeners();
    await _guardar();
  }

  Future<void> guardarSentimientos(String texto) async {
    _datos.sentimientos = texto;
    notifyListeners();
    await _guardar();
  }

  // ═══════════════════════════════════════════
  // CONTRASEÑAS ENCRIPTADAS
  // ═══════════════════════════════════════════

  Future<void> agregarContrasena(Contrasena contrasena) async {
    _datos.contrasenas.add(contrasena);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> editarContrasena(int index, Contrasena contrasena) async {
    if (index < 0 || index >= _datos.contrasenas.length) return;
    _datos.contrasenas[index] = contrasena;
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarContrasena(int index) async {
    if (index < 0 || index >= _datos.contrasenas.length) return;
    _datos.contrasenas.removeAt(index);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  // ═══════════════════════════════════════════
  // MARCADORES
  // ═══════════════════════════════════════════

  Future<void> agregarMarcador(Marcador marcador) async {
    _datos.marcadores.add(marcador);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> editarMarcador(int index, Marcador marcador) async {
    if (index < 0 || index >= _datos.marcadores.length) return;
    _datos.marcadores[index] = marcador;
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarMarcador(int index) async {
    if (index < 0 || index >= _datos.marcadores.length) return;
    _datos.marcadores.removeAt(index);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  // ═══════════════════════════════════════════
  // PLANTILLAS
  // ═══════════════════════════════════════════

  Future<void> agregarPlantilla(PlantillaTarea p) async {
    _datos.plantillas.add(p);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> eliminarPlantilla(int index) async {
    if (index < 0 || index >= _datos.plantillas.length) return;
    _datos.plantillas.removeAt(index);
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> usarPlantilla(int index,
      {String destino = 'criticas', String? nombrePersonalizado}) async {
    if (index < 0 || index >= _datos.plantillas.length) return;
    final tarea = _datos.plantillas[index].generarTarea();
    if (nombrePersonalizado != null && nombrePersonalizado.isNotEmpty) {
      tarea.titulo = nombrePersonalizado;
    }
    if (destino == 'criticas') {
      _datos.tareasCriticas.add(tarea);
    } else {
      final lista = _datos.listasPersonalizadas
          .where((l) => l.id == destino).firstOrNull;
      if (lista != null) {
        lista.tareas.add(tarea);
      } else {
        _datos.tareasCriticas.add(tarea);
      }
    }
    notifyListeners();
    await _guardar(inmediato: true);
  }

  // ═══════════════════════════════════════════
  // PAPELERA
  // ═══════════════════════════════════════════

  Future<void> restaurarDePapelera(int index) async {
    if (index < 0 || index >= _datos.papelera.length) return;
    final elem = _datos.papelera.removeAt(index);
    switch (elem.tipo) {
      case 'tarea_critica':
        _datos.tareasCriticas.add(Tarea.fromJson(elem.datosJson));
      case 'tarea_lista':
        final listaId = elem.datosJson['_listaId'] as String?;
        final datos = Map<String, dynamic>.from(elem.datosJson)..remove('_listaId');
        final tarea = Tarea.fromJson(datos);
        if (listaId != null) {
          final lista = _datos.listasPersonalizadas
              .where((l) => l.id == listaId).firstOrNull;
          if (lista != null) {
            lista.tareas.add(tarea);
          } else {
            _datos.tareasCriticas.add(tarea);
          }
        } else {
          _datos.tareasCriticas.add(tarea);
        }
      case 'cita':
        _datos.citas.add(Cita.fromJson(elem.datosJson));
    }
    notifyListeners();
    await _guardar(inmediato: true);
  }

  Future<void> eliminarDePapelera(int index) async {
    if (index < 0 || index >= _datos.papelera.length) return;
    _datos.papelera.removeAt(index);
    notifyListeners();
    await _guardar();
  }

  Future<void> vaciarPapelera() async {
    _datos.papelera.clear();
    notifyListeners();
    await _guardar();
  }

  // ═══════════════════════════════════════════
  /// Fuerza guardado en SQLite y subida inmediata a la nube (para cierre de app).
  Future<void> forzarGuardadoYSync() async {
    await _repositorio.guardarTodo(_datos);
    await _ejecutarSync();
  }

  // SYNC — EXPORT / IMPORT
  // ═══════════════════════════════════════════

  /// Exporta toda la agenda a un String JSON (formato SobreSync).
  /// Usa los datos EN MEMORIA (los que ves en pantalla), no re-lee de SQLite.
  String exportarAJsonSync() {
    final deviceId = _repositorio is AlmacenamientoSqlite
        ? _repositorio.dispositivoId
        : 'unknown';
    final sobre = SobreSync.ahora(
      datos: _datos,
      dispositivoOrigen: deviceId,
    );
    return jsonEncode(sobre.toJson());
  }

  Future<String> exportarAJson() async {
    return exportarAJsonSync();
  }

  /// Importa un String JSON y reemplaza todos los datos locales.
  /// Recarga el estado en memoria tras la importación.
  Future<void> importarDeJson(String jsonStr) async {
    if (_repositorio is AlmacenamientoSqlite) {
      await _repositorio.importarDeJson(jsonStr);
      // Recargar en memoria para que la UI se actualice
      final nuevos = await _repositorio.cargarTodo();
      _datos.tareasCriticas
        ..clear()
        ..addAll(nuevos.tareasCriticas);
      _datos.listasPersonalizadas
        ..clear()
        ..addAll(nuevos.listasPersonalizadas);
      _datos.citas
        ..clear()
        ..addAll(nuevos.citas);
      _datos.etiquetas
        ..clear()
        ..addAll(nuevos.etiquetas);
      _datos.personas
        ..clear()
        ..addAll(nuevos.personas);
      _datos.contrasenas
        ..clear()
        ..addAll(nuevos.contrasenas);
      _datos.marcadores
        ..clear()
        ..addAll(nuevos.marcadores);
      _datos.notas = nuevos.notas;
      _datos.sentimientos = nuevos.sentimientos;
      notifyListeners();
      return;
    }
    throw UnsupportedError('Import solo soportado con SQLite');
  }
}
