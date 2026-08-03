import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../modelos/datos_agenda.dart';
import '../modelos/sobre_sync.dart';
import '../modelos/tarea.dart';
import '../modelos/lista_personalizada.dart';
import '../modelos/etiqueta.dart';
import '../modelos/cita.dart';
import '../modelos/contrasena.dart';
import '../modelos/marcador.dart';
import '../modelos/papelera.dart';
import '../modelos/plantilla.dart';
import '../modelos/configuracion.dart';
import 'almacenamiento_repository.dart';

/// Implementación SQLite de AlmacenamientoRepository.
///
/// Esquema:
///   dispositivos     — config visual POR DISPOSITIVO (paleta, columnas, etc.)
///   tareas_criticas  — tareas críticas compartidas
///   subtareas        — subtareas (de críticas y de listas)
///   listas           — listas personalizadas
///   tareas_lista     — tareas dentro de listas
///   citas            — citas/eventos
///   etiquetas        — etiquetas (tareas/citas)
///   personas         — personas para delegar
///   textos           — notas y sentimientos (clave-valor)
///   contrasenas      — contraseñas encriptadas
///   marcadores       — bookmarks
class AlmacenamientoSqlite implements AlmacenamientoRepository {
  final String dispositivoId;
  Database? _db;
  String? _rutaPersonalizada;

  AlmacenamientoSqlite({
    required this.dispositivoId,
    String? rutaDb,
  }) : _rutaPersonalizada = rutaDb;

  set rutaDb(String? ruta) {
    if (_rutaPersonalizada != ruta) {
      _db?.close();
      _db = null;
      _rutaPersonalizada = ruta;
    }
  }

  String? get rutaDb => _rutaPersonalizada;

  Future<Database> _abrir() async {
    if (_db != null && _db!.isOpen) return _db!;

    String ruta;
    if (_rutaPersonalizada != null && _rutaPersonalizada!.isNotEmpty) {
      var r = _rutaPersonalizada!;
      // Si la ruta es una carpeta (no termina en .db), añadir agenda.db
      if (!r.endsWith('.db')) {
        r = '$r${Platform.pathSeparator}agenda.db';
      }
      final dir = Directory(File(r).parent.path);
      if (!await dir.exists()) await dir.create(recursive: true);
      ruta = r;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      ruta = '${dir.path}${Platform.pathSeparator}agenda.db';
    }

    _db = await databaseFactory.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, version) => _crearTablas(db),
        onUpgrade: (db, oldVersion, newVersion) => _migrar(db, oldVersion),
        onOpen: (db) => _repararEsquema(db),
      ),
    );
    return _db!;
  }

  /// Se ejecuta SIEMPRE al abrir la BD, sin importar la versión.
  /// Añade columnas y tablas faltantes de forma idempotente.
  Future<void> _repararEsquema(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(dispositivos)');
    final nombres = cols.map((c) => c['name'] as String).toSet();
    final requeridas = {
      'tamano_letra': 'REAL DEFAULT 14',
      'icono_app': "TEXT DEFAULT '📋'",
      'frases': "TEXT DEFAULT ''",
      'resumen_diario': 'INTEGER DEFAULT 1',
    };
    for (final e in requeridas.entries) {
      if (!nombres.contains(e.key)) {
        await db.execute(
            'ALTER TABLE dispositivos ADD COLUMN ${e.key} ${e.value}');
      }
    }
    await db.execute('''CREATE TABLE IF NOT EXISTS papelera (
      id TEXT PRIMARY KEY, tipo TEXT NOT NULL, titulo TEXT NOT NULL,
      fecha_eliminado TEXT NOT NULL, datos_json TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS plantillas (
      id TEXT PRIMARY KEY, nombre TEXT NOT NULL, datos_json TEXT NOT NULL)''');
  }

  Future<void> _migrar(Database db, int oldVersion) async {
    // Comprobar SIEMPRE todas las columnas de dispositivos (idempotente)
    final cols = await db.rawQuery('PRAGMA table_info(dispositivos)');
    final nombres = cols.map((c) => c['name'] as String).toSet();
    final columnasRequeridas = {
      'tamano_letra': 'REAL DEFAULT 14',
      'icono_app': "TEXT DEFAULT '📋'",
      'frases': "TEXT DEFAULT ''",
      'resumen_diario': 'INTEGER DEFAULT 1',
    };
    for (final entry in columnasRequeridas.entries) {
      if (!nombres.contains(entry.key)) {
        await db.execute(
            'ALTER TABLE dispositivos ADD COLUMN ${entry.key} ${entry.value}');
      }
    }

    // Tablas nuevas (IF NOT EXISTS = seguro de ejecutar siempre)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS papelera (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        fecha_eliminado TEXT NOT NULL,
        datos_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantillas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearTablas(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE dispositivos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        modo_oscuro INTEGER DEFAULT 0,
        paleta TEXT DEFAULT 'verde',
        columnas INTEGER DEFAULT 1,
        distribucion TEXT,
        titulo TEXT DEFAULT 'Agenda',
        tamano_letra REAL DEFAULT 14,
        icono_app TEXT DEFAULT '📋',
        frases TEXT DEFAULT '',
        resumen_diario INTEGER DEFAULT 1
      )
    ''');

    batch.execute('''
      CREATE TABLE tareas_criticas (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        fecha_limite TEXT,
        etiqueta TEXT,
        estado TEXT DEFAULT 'pendiente',
        persona TEXT,
        fecha_migrar TEXT,
        fecha_creacion TEXT,
        fecha_completada TEXT,
        orden INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE subtareas (
        id TEXT PRIMARY KEY,
        padre_id TEXT NOT NULL,
        texto TEXT NOT NULL,
        estado TEXT DEFAULT 'pendiente',
        persona TEXT,
        fecha_migrar TEXT,
        orden INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE listas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        emoji TEXT DEFAULT '📋',
        color TEXT DEFAULT '#4ecdc4',
        orden INTEGER DEFAULT 0,
        fecha_creacion TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE tareas_lista (
        id TEXT PRIMARY KEY,
        lista_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        fecha_limite TEXT,
        etiqueta TEXT,
        estado TEXT DEFAULT 'pendiente',
        persona TEXT,
        fecha_migrar TEXT,
        fecha_creacion TEXT,
        fecha_completada TEXT,
        orden INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE citas (
        id TEXT PRIMARY KEY,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        etiqueta TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE etiquetas (
        nombre TEXT NOT NULL,
        emoji TEXT DEFAULT '📌',
        color TEXT DEFAULT '#4ecdc4',
        tipo TEXT DEFAULT 'tareas',
        PRIMARY KEY (nombre, tipo)
      )
    ''');

    batch.execute('CREATE TABLE personas (nombre TEXT PRIMARY KEY)');

    batch.execute('''
      CREATE TABLE textos (
        clave TEXT PRIMARY KEY,
        valor TEXT DEFAULT ''
      )
    ''');

    batch.execute('''
      CREATE TABLE contrasenas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        valor_encriptado TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE marcadores (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        url TEXT NOT NULL,
        icono TEXT DEFAULT '🔗',
        orden INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE papelera (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        fecha_eliminado TEXT NOT NULL,
        datos_json TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE plantillas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        datos_json TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════
  // CARGAR TODO
  // ═══════════════════════════════════════════

  @override
  Future<DatosAgenda> cargarTodo() async {
    final db = await _abrir();

    // 1. Config del dispositivo actual
    final configRows = await db.query('dispositivos',
        where: 'id = ?', whereArgs: [dispositivoId]);
    Configuracion config;
    if (configRows.isNotEmpty) {
      final r = configRows.first;
      config = Configuracion(
        dispositivoNombre: r['nombre'] as String? ?? dispositivoId,
        modoOscuro: (r['modo_oscuro'] as int? ?? 0) == 1,
        paleta: r['paleta'] as String? ?? 'verde',
        columnas: r['columnas'] as int? ?? 1,
        distribucion: r['distribucion'] as String? ?? Configuracion.defaultDist,
        titulo: r['titulo'] as String? ?? 'Agenda',
        tamanoLetra: (r['tamano_letra'] as num?)?.toDouble() ?? 14,
        iconoApp: r['icono_app'] as String? ?? '📋',
        frases: r['frases'] as String? ?? '',
        resumenDiario: (r['resumen_diario'] as int? ?? 1) == 1,
      );
    } else {
      config = Configuracion(dispositivoNombre: dispositivoId);
      await db.insert('dispositivos', {
        'id': dispositivoId,
        'nombre': dispositivoId,
        'modo_oscuro': 0,
        'paleta': 'verde',
        'columnas': 1,
        'distribucion': Configuracion.defaultDist,
        'titulo': 'Agenda',
        'tamano_letra': 14,
        'icono_app': '📋',
        'frases': '',
      });
    }

    // 2. Tareas críticas + subtareas
    final tcRows = await db.query('tareas_criticas', orderBy: 'orden');
    final tareasCriticas = <Tarea>[];
    for (final r in tcRows) {
      final subs = await db.query('subtareas',
          where: 'padre_id = ?', whereArgs: [r['id']], orderBy: 'orden');
      tareasCriticas.add(_rowToTarea(r, subs));
    }

    // 3. Listas + sus tareas + subtareas
    final listasRows = await db.query('listas', orderBy: 'orden');
    final listas = <ListaPersonalizada>[];
    for (final lr in listasRows) {
      final tareasRows = await db.query('tareas_lista',
          where: 'lista_id = ?', whereArgs: [lr['id']], orderBy: 'orden');
      final tareas = <Tarea>[];
      for (final tr in tareasRows) {
        final subs = await db.query('subtareas',
            where: 'padre_id = ?', whereArgs: [tr['id']], orderBy: 'orden');
        tareas.add(_rowToTarea(tr, subs));
      }
      listas.add(ListaPersonalizada(
        id: lr['id'] as String,
        nombre: lr['nombre'] as String? ?? '',
        emoji: lr['emoji'] as String? ?? '📋',
        color: lr['color'] as String? ?? '#4ecdc4',
        orden: lr['orden'] as int? ?? 0,
        fechaCreacion: lr['fecha_creacion'] as String?,
        tareas: tareas,
      ));
    }

    // 4. Citas
    final citasRows = await db.query('citas');
    final citas = citasRows
        .map((r) => Cita(
              id: r['id'] as String,
              fecha: r['fecha'] as String,
              hora: r['hora'] as String,
              descripcion: r['descripcion'] as String,
              etiqueta: r['etiqueta'] as String?,
            ))
        .toList();

    // 5. Etiquetas
    final etRows = await db.query('etiquetas');
    final etiquetas = etRows
        .map((r) => Etiqueta(
              nombre: r['nombre'] as String,
              emoji: r['emoji'] as String? ?? '📌',
              color: r['color'] as String? ?? '#4ecdc4',
              tipo: r['tipo'] as String? ?? 'tareas',
            ))
        .toList();

    // 6. Personas
    final persRows = await db.query('personas');
    final personas = persRows.map((r) => r['nombre'] as String).toList();

    // 7. Textos (notas, sentimientos)
    final textRows = await db.query('textos');
    String notas = '', sentimientos = '';
    for (final r in textRows) {
      if (r['clave'] == 'notas') notas = r['valor'] as String? ?? '';
      if (r['clave'] == 'sentimientos') {
        sentimientos = r['valor'] as String? ?? '';
      }
    }

    // 8. Contraseñas
    final contRows = await db.query('contrasenas');
    final contrasenas = contRows
        .map((r) => Contrasena(
              id: r['id'] as String,
              nombre: r['nombre'] as String,
              valorEncriptado: r['valor_encriptado'] as String,
            ))
        .toList();

    // 9. Marcadores
    final marcRows = await db.query('marcadores', orderBy: 'orden');
    final marcadores = marcRows
        .map((r) => Marcador(
              id: r['id'] as String,
              nombre: r['nombre'] as String,
              url: r['url'] as String,
              icono: r['icono'] as String? ?? '🔗',
            ))
        .toList();

    // 10. Papelera
    final papRows = await db.query('papelera');
    final papelera = papRows
        .map((r) => ElementoPapelera(
              id: r['id'] as String,
              tipo: r['tipo'] as String,
              titulo: r['titulo'] as String,
              fechaEliminado: r['fecha_eliminado'] as String,
              datosJson: jsonDecode(r['datos_json'] as String) as Map<String, dynamic>,
            ))
        .where((e) => !e.expirado)
        .toList();

    return DatosAgenda(
      tareasCriticas: tareasCriticas,
      listasPersonalizadas: listas,
      etiquetas: etiquetas,
      personas: personas,
      configuracion: config,
      citas: citas,
      notas: notas,
      sentimientos: sentimientos,
      contrasenas: contrasenas,
      marcadores: marcadores,
      papelera: papelera,
      plantillas: await _cargarPlantillas(db),
    );
  }

  Future<List<PlantillaTarea>> _cargarPlantillas(Database db) async {
    try {
      final rows = await db.query('plantillas');
      return rows.map((r) {
        final datos = jsonDecode(r['datos_json'] as String) as Map<String, dynamic>;
        return PlantillaTarea.fromJson({...datos, 'id': r['id'], 'nombre': r['nombre']});
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Tarea _rowToTarea(Map<String, Object?> r, List<Map<String, Object?>> subs) {
    return Tarea(
      id: r['id'] as String,
      titulo: r['titulo'] as String,
      fechaLimite: r['fecha_limite'] as String?,
      etiqueta: r['etiqueta'] as String?,
      estado: r['estado'] as String? ?? 'pendiente',
      persona: r['persona'] as String?,
      fechaMigrar: r['fecha_migrar'] as String?,
      fechaCreacion: r['fecha_creacion'] as String?,
      fechaCompletada: r['fecha_completada'] as String?,
      subtareas: subs
          .map((s) => Subtarea(
                id: s['id'] as String,
                texto: s['texto'] as String,
                estado: s['estado'] as String? ?? 'pendiente',
                persona: s['persona'] as String?,
                fechaMigrar: s['fecha_migrar'] as String?,
              ))
          .toList(),
    );
  }

  // ═══════════════════════════════════════════
  // GUARDAR TODO
  // ═══════════════════════════════════════════

  @override
  Future<void> guardarTodo(DatosAgenda datos) async {
    final db = await _abrir();
    final c = datos.configuracion;

    await db.transaction((txn) async {
      // ── Config dispositivo (upsert) ──
      await txn.delete('dispositivos',
          where: 'id = ?', whereArgs: [dispositivoId]);
      await txn.insert('dispositivos', {
        'id': dispositivoId,
        'nombre': c.dispositivoNombre.isEmpty ? dispositivoId : c.dispositivoNombre,
        'modo_oscuro': c.modoOscuro ? 1 : 0,
        'paleta': c.paleta,
        'columnas': c.columnas,
        'distribucion': c.distribucion,
        'titulo': c.titulo,
        'tamano_letra': c.tamanoLetra,
        'icono_app': c.iconoApp,
        'frases': c.frases,
        'resumen_diario': c.resumenDiario ? 1 : 0,
      });

      // ── Limpiar datos compartidos ──
      await txn.delete('tareas_criticas');
      await txn.delete('subtareas');
      await txn.delete('listas');
      await txn.delete('tareas_lista');
      await txn.delete('citas');
      await txn.delete('etiquetas');
      await txn.delete('personas');
      await txn.delete('textos');
      await txn.delete('contrasenas');
      await txn.delete('marcadores');

      // ── Tareas críticas ──
      for (var i = 0; i < datos.tareasCriticas.length; i++) {
        final t = datos.tareasCriticas[i];
        await txn.insert('tareas_criticas', _tareaToRow(t, i));
        await _insertarSubtareas(txn, t);
      }

      // ── Listas + tareas ──
      for (var i = 0; i < datos.listasPersonalizadas.length; i++) {
        final l = datos.listasPersonalizadas[i];
        await txn.insert('listas', {
          'id': l.id,
          'nombre': l.nombre,
          'emoji': l.emoji,
          'color': l.color,
          'orden': i,
          'fecha_creacion': l.fechaCreacion,
        });
        for (var j = 0; j < l.tareas.length; j++) {
          final t = l.tareas[j];
          await txn.insert('tareas_lista', {
            ..._tareaToRow(t, j),
            'lista_id': l.id,
          });
          await _insertarSubtareas(txn, t);
        }
      }

      // ── Citas ──
      for (final ci in datos.citas) {
        await txn.insert('citas', {
          'id': ci.id,
          'fecha': ci.fecha,
          'hora': ci.hora,
          'descripcion': ci.descripcion,
          'etiqueta': ci.etiqueta,
        });
      }

      // ── Etiquetas ──
      for (final e in datos.etiquetas) {
        await txn.insert('etiquetas', {
          'nombre': e.nombre,
          'emoji': e.emoji,
          'color': e.color,
          'tipo': e.tipo,
        });
      }

      // ── Personas ──
      for (final p in datos.personas) {
        await txn.insert('personas', {'nombre': p});
      }

      // ── Textos ──
      await txn.insert('textos', {'clave': 'notas', 'valor': datos.notas});
      await txn.insert(
          'textos', {'clave': 'sentimientos', 'valor': datos.sentimientos});

      // ── Contraseñas ──
      for (final co in datos.contrasenas) {
        await txn.insert('contrasenas', {
          'id': co.id,
          'nombre': co.nombre,
          'valor_encriptado': co.valorEncriptado,
        });
      }

      // ── Marcadores ──
      for (var i = 0; i < datos.marcadores.length; i++) {
        final m = datos.marcadores[i];
        await txn.insert('marcadores', {
          'id': m.id,
          'nombre': m.nombre,
          'url': m.url,
          'icono': m.icono,
          'orden': i,
        });
      }

      // ── Papelera ──
      await txn.delete('papelera');
      for (final p in datos.papelera.where((e) => !e.expirado)) {
        await txn.insert('papelera', {
          'id': p.id,
          'tipo': p.tipo,
          'titulo': p.titulo,
          'fecha_eliminado': p.fechaEliminado,
          'datos_json': jsonEncode(p.datosJson),
        });
      }

      // ── Plantillas ──
      await txn.delete('plantillas');
      for (final p in datos.plantillas) {
        await txn.insert('plantillas', {
          'id': p.id,
          'nombre': p.nombre,
          'datos_json': jsonEncode(p.toJson()),
        });
      }
    });
  }

  Map<String, Object?> _tareaToRow(Tarea t, int orden) => {
        'id': t.id,
        'titulo': t.titulo,
        'fecha_limite': t.fechaLimite,
        'etiqueta': t.etiqueta,
        'estado': t.estado,
        'persona': t.persona,
        'fecha_migrar': t.fechaMigrar,
        'fecha_creacion': t.fechaCreacion,
        'fecha_completada': t.fechaCompletada,
        'orden': orden,
      };

  Future<void> _insertarSubtareas(Transaction txn, Tarea t) async {
    for (var k = 0; k < t.subtareas.length; k++) {
      final s = t.subtareas[k];
      await txn.insert('subtareas', {
        'id': s.id,
        'padre_id': t.id,
        'texto': s.texto,
        'estado': s.estado,
        'persona': s.persona,
        'fecha_migrar': s.fechaMigrar,
        'orden': k,
      });
    }
  }

  // ═══════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════

  /// Lee la ruta personalizada de la BD desde un archivo local.
  static Future<String?> leerRutaLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}agenda_ruta.txt');
      if (await f.exists()) {
        final ruta = (await f.readAsString()).trim();
        return ruta.isEmpty ? null : ruta;
      }
    } catch (_) {}
    return null;
  }

  /// Guarda la ruta personalizada de la BD en un archivo local.
  static Future<void> guardarRutaLocal(String? ruta) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}${Platform.pathSeparator}agenda_ruta.txt');
    await f.writeAsString(ruta ?? '');
  }

  /// Detecta un ID único para este dispositivo basado en el hostname.
  // ═══════════════════════════════════════════
  // EXPORT / IMPORT JSON (para sincronización)
  // ═══════════════════════════════════════════

  /// Exporta TODOS los datos de SQLite a un String JSON envuelto en SobreSync.
  /// Este es el JSON que se sube a la nube.
  ///
  /// Flujo: SQLite → cargarTodo() → DatosAgenda → SobreSync → jsonEncode()
  Future<String> exportarAJson() async {
    final datos = await cargarTodo();
    final sobre = SobreSync.ahora(
      datos: datos,
      dispositivoOrigen: dispositivoId,
    );
    return jsonEncode(sobre.toJson());
  }

  /// Importa un String JSON (formato SobreSync) y reemplaza todo el SQLite.
  /// Transaccional: si algo falla, SQLite queda como estaba.
  ///
  /// Flujo: jsonDecode() → SobreSync → DatosAgenda → guardarTodo() → SQLite
  Future<SobreSync> importarDeJson(String jsonStr) async {
    final mapa = jsonDecode(jsonStr) as Map<String, dynamic>;
    final sobre = SobreSync.fromJson(mapa);
    // Preservar la config visual de ESTE dispositivo (no la del que subió)
    final datosActuales = await cargarTodo();
    final miConfig = datosActuales.configuracion;
    // Importar los datos compartidos pero mantener MI config
    sobre.datos.configuracion = miConfig;
    await guardarTodo(sobre.datos);
    return sobre;
  }

  /// Guarda el timestamp de la última sincronización exitosa en un archivo local.
  Future<void> guardarTimestampSync(int timestamp) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}${Platform.pathSeparator}agenda_sync_ts.txt');
    await f.writeAsString('$timestamp');
  }

  /// Lee el timestamp de la última sincronización exitosa.
  Future<int> leerTimestampSync() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}agenda_sync_ts.txt');
      if (await f.exists()) {
        return int.tryParse(await f.readAsString()) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Indica si hay cambios locales que aún no se han subido a la nube.
  /// Compara el timestamp del archivo .db con el de la última sync.
  Future<bool> hayCambiosPendientes() async {
    final tsSync = await leerTimestampSync();
    if (tsSync == 0) return true; // Nunca sincronizado
    final db = await _abrir();
    final ruta = db.path;
    try {
      final stat = await File(ruta).stat();
      return stat.modified.toUtc().millisecondsSinceEpoch > tsSync;
    } catch (_) {
      return true;
    }
  }

  // ═══════════════════════════════════════════
  // UTILIDADES ESTÁTICAS
  // ═══════════════════════════════════════════

  static String detectarDispositivoId() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'dispositivo-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
