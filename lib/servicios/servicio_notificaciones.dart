import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../modelos/cita.dart';

class ServicioNotificaciones {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;
  static Timer? _timerDesktop;
  static List<Cita> _citasPendientes = [];
  static int _minutosAntes = 15;
  static final Set<String> _notificadas = {};

  static const _androidChannel = AndroidNotificationDetails(
    'citas_agenda',
    'Recordatorios de citas',
    channelDescription: 'Aviso antes de cada cita',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static Future<void> inicializar() async {
    if (_inicializado) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);

      // Solicitar permiso de notificaciones en Android 13+
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
      }
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _timerDesktop?.cancel();
      _timerDesktop = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _comprobarDesktop(),
      );
    }

    _inicializado = true;
  }

  /// Envía una notificación de prueba inmediata.
  static Future<void> enviarPrueba() async {
    if (!_inicializado) await inicializar();
    await _plugin.show(
      0,
      '📅 Prueba de notificación',
      'Las notificaciones funcionan correctamente',
      const NotificationDetails(android: _androidChannel),
    );
  }

  static String _textoAntes(int min) {
    if (min < 60) return '$min min';
    if (min == 60) return '1 hora';
    if (min < 1440) return '${min ~/ 60}h';
    return '${min ~/ 1440} día${min ~/ 1440 > 1 ? 's' : ''}';
  }

  /// Programa TODOS los recordatorios de una cita según su lista.
  static Future<void> programarRecordatorio(Cita cita,
      {int minutosAntes = 15}) async {
    if (!_inicializado || (!Platform.isAndroid && !Platform.isIOS)) return;
    final lista = cita.recordatorios.isEmpty ? [minutosAntes] : cita.recordatorios;
    for (final min in lista) {
      await _programarUno(cita, min);
    }
  }

  static Future<void> _programarUno(Cita cita, int minutosAntes) async {
    final fechaHora = cita.fechaHora;
    if (fechaHora.year < 2000) return;
    final horaNotif = fechaHora.subtract(Duration(minutes: minutosAntes));
    if (horaNotif.isBefore(DateTime.now())) return;

    final tzFecha = tz.TZDateTime.from(horaNotif, tz.local);
    // ID único por cita + minutos (para poder cancelar individualmente)
    final id = (cita.id.hashCode.abs() + minutosAntes * 31) % 2147483647;
    final texto = _textoAntes(minutosAntes);

    await _plugin.zonedSchedule(
      id,
      '📅 Cita en $texto',
      '${cita.hora} — ${cita.descripcion}',
      tzFecha,
      const NotificationDetails(android: _androidChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelarRecordatorio(Cita cita) async {
    if (!_inicializado || (!Platform.isAndroid && !Platform.isIOS)) return;
    final lista = cita.recordatorios.isEmpty ? [15] : cita.recordatorios;
    for (final min in lista) {
      final id = (cita.id.hashCode.abs() + min * 31) % 2147483647;
      await _plugin.cancel(id);
    }
  }

  static Future<void> reprogramarTodas(List<Cita> citas,
      {int minutosAntes = 15}) async {
    if (!_inicializado) return;
    _minutosAntes = minutosAntes;
    _citasPendientes = List.from(citas);

    if (Platform.isAndroid || Platform.isIOS) {
      await _plugin.cancelAll();
      for (final c in citas) {
        await programarRecordatorio(c, minutosAntes: minutosAntes);
      }
    }
  }

  static Future<void> _comprobarDesktop() async {
    final ahora = DateTime.now();
    for (final cita in _citasPendientes) {
      if (_notificadas.contains(cita.id)) continue;
      final diff = cita.fechaHora.difference(ahora).inMinutes;
      if (diff >= 0 && diff <= _minutosAntes) {
        _notificadas.add(cita.id);
        try {
          await _plugin.show(
            cita.id.hashCode.abs() % 2147483647,
            '📅 Cita en ${diff}min',
            '${cita.hora} — ${cita.descripcion}',
            null,
          );
        } catch (_) {}
      }
    }
  }
}
