import 'dart:io';
import 'package:home_widget/home_widget.dart';
import '../estado/agenda_estado.dart';

/// Actualiza el widget de la pantalla de inicio de Android con un
/// resumen de lo que hay que hacer hoy (como Google Tasks / Todoist).
///
/// Flujo:
///   Flutter escribe datos → HomeWidget.saveWidgetData (SharedPreferences)
///   → HomeWidget.updateWidget → Android redibuja el widget
///     leyendo esos datos en AgendaWidgetProvider.kt
///
/// Qué secciones se muestran es configurable desde Ajustes
/// (estado.widgetMostrarCriticas / widgetMostrarCitas / widgetMostrarHoy /
/// widgetMostrarListas).
///
/// Solo funciona en Android. En Windows no hace nada.
class ServicioWidget {
  /// Nombre de la clase Kotlin del widget (debe coincidir exactamente).
  static const _androidName = 'AgendaWidgetProvider';

  /// Máximo de líneas por sección para no saturar el widget.
  static const _maxPorSeccion = 3;

  /// Máximo de listas personales a mostrar, y máximo de tareas por lista.
  static const _maxListas = 2;
  static const _maxTareasPorLista = 3;

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  /// Actualiza el widget con el estado actual de la agenda.
  static Future<void> actualizar(AgendaEstado estado) async {
    if (!Platform.isAndroid) return;

    try {
      final hoy = DateTime.now();
      final fechaStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      // ── Citas de hoy ──
      var citasTxt = '';
      var totalCitas = 0;
      if (estado.widgetMostrarCitas) {
        final citas = estado.citasDelDia(fechaStr);
        totalCitas = citas.length;
        citasTxt = citas
            .take(_maxPorSeccion)
            .map((c) => '🕐 ${c.hora}  ${c.descripcion}')
            .join('\n');
      }

      // ── Tareas críticas pendientes (aunque no sean de hoy) ──
      var criticasTxt = '';
      var totalCriticas = 0;
      if (estado.widgetMostrarCriticas) {
        final criticas =
            estado.tareasCriticas.where((t) => !t.completada).toList();
        totalCriticas = criticas.length;
        criticasTxt = criticas
            .take(_maxPorSeccion)
            .map((t) => '🔴 ${t.titulo}')
            .join('\n');
      }

      // ── Tareas de hoy (sin duplicar las que ya son críticas) ──
      var hoyTxt = '';
      var totalHoy = 0;
      if (estado.widgetMostrarHoy) {
        final criticasIds = estado.tareasCriticas.map((t) => t.id).toSet();
        final tareasHoy = estado
            .tareasDelDia(fechaStr)
            .where((t) => !t.completada && !criticasIds.contains(t.id))
            .toList();
        totalHoy = tareasHoy.length;
        hoyTxt = tareasHoy
            .take(_maxPorSeccion)
            .map((t) => '●  ${t.titulo}')
            .join('\n');
      }

      // ── Listas personales: nombre de la lista + sus tareas pendientes ──
      var listasTxt = '';
      var totalListas = 0;
      if (estado.widgetMostrarListas) {
        final listas = estado.listasPersonalizadas.toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));
        final bloques = <String>[];
        for (final lista in listas) {
          final pendientes =
              lista.tareas.where((t) => !t.completada).toList();
          if (pendientes.isEmpty) continue;
          totalListas += pendientes.length;
          if (bloques.length >= _maxListas) continue;

          final tareasTxt = pendientes
              .take(_maxTareasPorLista)
              .map((t) => '   ‣ ${t.titulo}')
              .join('\n');
          final resto = pendientes.length - _maxTareasPorLista;
          final bloque = resto > 0
              ? '${lista.emoji} ${lista.nombre}\n$tareasTxt\n   … y $resto más'
              : '${lista.emoji} ${lista.nombre}\n$tareasTxt';
          bloques.add(bloque);
        }
        listasTxt = bloques.join('\n');
      }

      final totalPendiente =
          totalCitas + totalCriticas + totalHoy + totalListas;
      final titulo = '${estado.iconoApp}  ${estado.titulo}';
      final fecha =
          '${_dias[hoy.weekday - 1]} ${hoy.day} ${_meses[hoy.month - 1]}';

      // ── Guardar y refrescar ──
      await HomeWidget.saveWidgetData<String>('titulo_widget', titulo);
      await HomeWidget.saveWidgetData<String>('fecha_widget', fecha);
      await HomeWidget.saveWidgetData<String>('contador_widget', '$totalPendiente');
      await HomeWidget.saveWidgetData<String>('citas_widget', citasTxt);
      await HomeWidget.saveWidgetData<String>('criticas_widget', criticasTxt);
      await HomeWidget.saveWidgetData<String>('hoy_widget', hoyTxt);
      await HomeWidget.saveWidgetData<String>('listas_widget', listasTxt);
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (_) {
      // Si no hay widget colocado o falla, no bloquear la app
    }
  }
}
