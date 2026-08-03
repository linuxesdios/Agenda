import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'servicios/servicio_notificaciones.dart';
import 'servicios/servicio_widget.dart';
import 'repositorios/almacenamiento_sqlite.dart';
import 'estado/agenda_estado.dart';
import 'modelos/configuracion.dart';
import 'modelos/datos_agenda.dart';
import 'pantallas/pantalla_principal.dart';
import 'i18n/idioma.dart';
import 'i18n/traducciones.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logFile = File(
      '${Directory.current.path}${Platform.pathSeparator}agenda_log.txt');
  void log(String msg) {
    final line = '[${DateTime.now()}] $msg';
    try {
      logFile.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}
  }

  try {
    log('Iniciando app...');

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
    }

    final dispositivoId = AlmacenamientoSqlite.detectarDispositivoId();
    final rutaDb = await AlmacenamientoSqlite.leerRutaLocal();

    final repositorio = AlmacenamientoSqlite(
      dispositivoId: dispositivoId,
      rutaDb: rutaDb,
    );

    DatosAgenda datos;
    try {
      datos = await repositorio.cargarTodo();
      log('Datos cargados OK');
    } catch (e) {
      log('ERROR cargando: $e');
      datos = DatosAgenda();
    }

    final estado = AgendaEstado(
      repositorio: repositorio,
      datosIniciales: datos,
    );
    await estado.asegurarIdiomaDetectado();

    // Sincronizar con la nube al arrancar (lee el .db ANTES de que la
    // limpieza de citas pasadas lo modifique, para que la comparación de
    // fechas de sincronizarAhora() refleje ediciones reales del usuario,
    // no el auto-purge de más abajo).
    try {
      log('Sincronizando al arrancar...');
      await estado.sincronizarAhora();
      log('Sync al arrancar: ${estado.estadoSync}');
    } catch (e) {
      log('Sync al arrancar no disponible: $e');
    }

    // Borrar citas pasadas automáticamente (después de aplicar la nube,
    // para no purgar citas que en realidad venían actualizadas de otro
    // dispositivo).
    try {
      final borradas = await estado.borrarCitasPasadas();
      if (borradas > 0) log('Borradas $borradas citas pasadas');
    } catch (e) {
      log('Error borrando citas pasadas: $e');
    }

    // Inicializar notificaciones
    try {
      await ServicioNotificaciones.inicializar();
      await ServicioNotificaciones.reprogramarTodas(estado.citas);
      log('Notificaciones OK');
    } catch (e) {
      log('Notificaciones no disponibles: $e');
    }

    log('Lanzando runApp...');

    // Refrescar el widget de Android al arrancar
    try {
      await ServicioWidget.actualizar(estado);
    } catch (e) {
      log('Widget no disponible: $e');
    }

    runApp(
      ChangeNotifierProvider.value(
        value: estado,
        child: const AgendaApp(),
      ),
    );
  } catch (e, stack) {
    log('ERROR FATAL: $e\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
                '${Traducciones.t(detectarIdiomaDelSistema(), 'app.error_fatal')}:\n$e',
                style: const TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ),
      ),
    ));
  }
}

/// Widget raíz con observador de ciclo de vida.
/// Guarda y sube a la nube cuando la app se cierra o va a segundo plano.
class AgendaApp extends StatefulWidget {
  const AgendaApp({super.key});

  @override
  State<AgendaApp> createState() => _AgendaAppState();
}

class _AgendaAppState extends State<AgendaApp>
    with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  /// Android/iOS: se llama cuando la app va a segundo plano o se cierra.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _guardarYSubir();
    }
  }

  /// Windows: se llama cuando el usuario pulsa la X.
  @override
  void onWindowClose() async {
    await _guardarYSubir();
    await windowManager.destroy();
  }

  Future<void> _guardarYSubir() async {
    try {
      final estado = context.read<AgendaEstado>();
      await estado.forzarGuardadoYSync();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final seedColor = Color(
      paletasDisponibles[estado.paleta]?.seedColor ?? 0xFF4ECDC4,
    );
    final fontSize = estado.tamanoLetra;

    return MaterialApp(
      title: estado.titulo,
      debugShowCheckedModeBanner: false,
      locale: Locale(estado.idioma.codigo),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('ru'),
        Locale('zh'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.light),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize),
          bodySmall: TextStyle(fontSize: fontSize - 2),
          titleMedium: TextStyle(fontSize: fontSize + 2),
          labelLarge: TextStyle(fontSize: fontSize),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor, brightness: Brightness.dark),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize),
          bodySmall: TextStyle(fontSize: fontSize - 2),
          titleMedium: TextStyle(fontSize: fontSize + 2),
          labelLarge: TextStyle(fontSize: fontSize),
        ),
      ),
      themeMode: estado.modoOscuro ? ThemeMode.dark : ThemeMode.light,
      home: const PantallaPrincipal(),
    );
  }
}
