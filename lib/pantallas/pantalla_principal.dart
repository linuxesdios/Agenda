import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/tarea.dart';
import '../modelos/cita.dart';
import '../modelos/lista_personalizada.dart';
import '../modelos/plantilla.dart';
import '../widgets/tarjeta_tarea.dart';
import '../widgets/dialogo_tarea.dart';
import '../widgets/dialogo_lista.dart';
import '../widgets/dialogo_cita.dart';
import '../widgets/dialogo_cita_periodica.dart';
import '../widgets/seccion_notas.dart';
import '../widgets/seccion_contrasenas.dart';
import '../widgets/seccion_marcadores.dart';
import '../widgets/seccion_pomodoro.dart';
import '../widgets/seccion_calendario.dart';
import '../widgets/seccion_vista_semanal.dart';
import '../widgets/seccion_kanban.dart';
import 'pantalla_ajustes.dart';
import 'pantalla_papelera.dart';
import 'pantalla_calendario.dart';
import '../servicios/cliente_nube.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/dialogo_resumen_diario.dart';
import '../i18n/calendario_i18n.dart';

/// Períodos de filtro disponibles, como en la app web.
enum FiltroPeriodo { hoy, semana, quincena, mes, todo }

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  FiltroPeriodo _filtro = FiltroPeriodo.todo;
  bool _resumenMostrado = false;
  bool _siempreArriba = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_resumenMostrado) {
      _resumenMostrado = true;
      Future.microtask(() {
        if (mounted) {
          final estado = context.read<AgendaEstado>();
          mostrarResumenSiCorresponde(context, estado);
        }
      });
    }
  }

  /// Comprueba si una fecha (YYYY-MM-DD) pasa el filtro de período actual.
  bool _pasaFiltro(String? fecha) {
    if (_filtro == FiltroPeriodo.todo) return true;
    if (fecha == null) return _filtro == FiltroPeriodo.todo;

    final partes = fecha.split('-');
    if (partes.length != 3) return true;
    final fechaObj = DateTime(
        int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
    final hoy = DateTime.now();
    final hoyLimpio = DateTime(hoy.year, hoy.month, hoy.day);
    final diff = fechaObj.difference(hoyLimpio).inDays;

    switch (_filtro) {
      case FiltroPeriodo.hoy:
        return diff == 0;
      case FiltroPeriodo.semana:
        return diff >= 0 && diff <= 7;
      case FiltroPeriodo.quincena:
        return diff >= 0 && diff <= 15;
      case FiltroPeriodo.mes:
        return diff >= 0 && diff <= 30;
      case FiltroPeriodo.todo:
        return true;
    }
  }

  /// Filtra tareas según el período. Las sin fecha se muestran siempre excepto en "Hoy".
  List<Tarea> _filtrarTareas(List<Tarea> tareas) {
    if (_filtro == FiltroPeriodo.todo) return tareas;
    return tareas.where((t) {
      if (t.soloFecha == null) return _filtro != FiltroPeriodo.hoy;
      return _pasaFiltro(t.soloFecha);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;

    final frase = estado.configuracion.fraseAleatoria;
    final fechaTexto = _fechaCorta();

    final esMovil = Platform.isAndroid || Platform.isIOS;
    final botones = [
      _buildIndicadorSync(estado.estadoSync),
      IconButton(
        icon: const Icon(Icons.sync),
        tooltip: estado.t('principal.tooltip_sincronizar'),
        onPressed: () => _sincronizarManual(estado),
      ),
      IconButton(
        icon: const Icon(Icons.view_kanban, size: 22),
        tooltip: estado.t('principal.tooltip_kanban'),
        onPressed: () => _mostrarKanban(context, estado),
      ),
      IconButton(
        icon: const Icon(Icons.auto_stories, size: 22),
        tooltip: estado.t('principal.tooltip_resumen_semana'),
        onPressed: () => _mostrarResumenSemanal(context, estado),
      ),
      if (Platform.isWindows)
        IconButton(
          icon: Icon(
            _siempreArriba ? Icons.push_pin : Icons.push_pin_outlined,
            size: 22,
            color: _siempreArriba ? Colors.orange : null,
          ),
          tooltip: _siempreArriba
              ? estado.t('principal.tooltip_quitar_siempre_arriba')
              : estado.t('principal.tooltip_siempre_arriba'),
          onPressed: _toggleSiempreArriba,
        ),
      IconButton(
        icon: const Icon(Icons.calendar_month, size: 22),
        tooltip: estado.t('calendario.titulo'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PantallaCalendario())),
      ),
      IconButton(
        icon: Icon(estado.modoOscuro ? Icons.light_mode : Icons.dark_mode, size: 22),
        tooltip: estado.modoOscuro
            ? estado.t('principal.tooltip_modo_claro')
            : estado.t('principal.tooltip_modo_oscuro'),
        onPressed: () => estado.cambiarModoOscuro(!estado.modoOscuro),
      ),
      IconButton(
        icon: const Icon(Icons.playlist_add, size: 22),
        tooltip: estado.t('principal.tooltip_nueva_lista'),
        onPressed: () => _crearLista(context, estado),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 22),
        tooltip: estado.t('principal.tooltip_papelera'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PantallaPapelera())),
      ),
      IconButton(
        icon: const Icon(Icons.settings, size: 22),
        tooltip: estado.t('principal.tooltip_ajustes'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PantallaAjustes())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: Text(estado.iconoApp, style: const TextStyle(fontSize: 26)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${estado.titulo}  —  $fechaTexto',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (frase.isNotEmpty)
              Text('"$frase"',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                      color: colors.onPrimaryContainer.withValues(alpha: 0.7)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        centerTitle: true,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        // En PC: botones en la misma fila. En móvil: sin actions (van abajo).
        actions: esMovil ? null : botones,
        // En móvil: segunda fila con los botones
        bottom: esMovil
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: colors.primaryContainer,
                  child: IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(38, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: botones,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => _sincronizarManual(estado),
        child: _buildBody(context, estado, colors),
      ),
      floatingActionButton: estado.plantillas.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _crearTarea(context, estado),
              icon: const Icon(Icons.add),
              label: Text(estado.t('principal.nueva_tarea')),
            )
          : FloatingActionButton.extended(
              onPressed: () => _menuCrearTarea(context, estado),
              icon: const Icon(Icons.add),
              label: Text(estado.t('principal.nueva_tarea')),
            ),
    );
  }

  // ═══════════════════════════════════════════
  // FILTRO DE PERÍODO (Hoy / Semana / 15 Días / Mes / Todo)
  // ═══════════════════════════════════════════

  Widget _buildFiltroPeriodo(ColorScheme colors, AgendaEstado estado) {
    final filtros = [
      (filtro: FiltroPeriodo.hoy, emoji: '🕐', texto: estado.t('principal.filtro_hoy')),
      (filtro: FiltroPeriodo.semana, emoji: '📅', texto: estado.t('principal.filtro_semana')),
      (filtro: FiltroPeriodo.quincena, emoji: '📆', texto: estado.t('principal.filtro_quincena')),
      (filtro: FiltroPeriodo.mes, emoji: '🗓️', texto: estado.t('principal.filtro_mes')),
      (filtro: FiltroPeriodo.todo, emoji: '📋', texto: estado.t('principal.filtro_todo')),
    ];

    return Center(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: filtros.map((f) {
          final activo = _filtro == f.filtro;
          return ChoiceChip(
            label: Text('${f.emoji} ${f.texto}'),
            selected: activo,
            onSelected: (_) => setState(() => _filtro = f.filtro),
            selectedColor: colors.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              fontWeight: activo ? FontWeight.bold : null,
              color: activo ? colors.primary : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LAYOUT
  // ═══════════════════════════════════════════

  Widget _buildBody(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    final dist = estado.configuracion.distribucionParseada
        .where((d) => d.ubicacion != 'hidden')
        .toList();
    final numCols = estado.columnas;

    final children = <Widget>[
      _buildFiltroPeriodo(colors, estado),
      const SizedBox(height: 12),
    ];

    var colGroup = <({String seccion, String ubicacion})>[];

    void flushColGroup() {
      if (colGroup.isEmpty) return;
      children
          .add(_buildRowColumnas(context, estado, colors, colGroup, numCols));
      colGroup = [];
    }

    for (final d in dist) {
      if (d.ubicacion == 'full') {
        flushColGroup();
        final w = _buildSeccionWidget(context, estado, colors, d.seccion);
        if (w != null) {
          children.add(w);
          children.add(const SizedBox(height: 12));
        }
      } else {
        colGroup.add(d);
      }
    }
    flushColGroup();
    children.add(const SizedBox(height: 80));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRowColumnas(
      BuildContext context,
      AgendaEstado estado,
      ColorScheme colors,
      List<({String seccion, String ubicacion})> grupo,
      int numCols) {
    final columnas = <int, List<String>>{};
    for (var i = 1; i <= numCols; i++) {
      columnas[i] = [];
    }
    for (final d in grupo) {
      final col = int.tryParse(d.ubicacion) ?? 1;
      columnas[col.clamp(1, numCols)]!.add(d.seccion);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(numCols, (i) {
          final secciones = columnas[i + 1] ?? [];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? 6 : 0,
                right: i < numCols - 1 ? 6 : 0,
              ),
              child: Column(
                children: secciones.expand((secId) {
                  final w =
                      _buildSeccionWidget(context, estado, colors, secId);
                  if (w == null) return <Widget>[];
                  return [w, const SizedBox(height: 12)];
                }).toList(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget? _buildSeccionWidget(
      BuildContext context, AgendaEstado estado, ColorScheme colors, String id) {
    switch (id) {
      case 'criticas':
        return _buildSeccionCriticas(context, estado, colors);
      case 'citas':
        return _buildSeccionCitas(context, estado, colors);
      case 'listas':
        return _buildSeccionListas(context, estado, colors);
      case 'notas':
        return const SeccionNotas();
      case 'sentimientos':
        return const SeccionSentimientos();
      case 'pomodoro':
        return const SeccionPomodoro();
      case 'marcadores':
        return const SeccionMarcadores();
      case 'contrasenas':
        return const SeccionContrasenas();
      case 'calendario':
        return const SeccionCalendario();
      case 'semanal':
        return const SeccionVistaSemanal();
      default:
        return null;
    }
  }

  Future<void> _toggleSiempreArriba() async {
    _siempreArriba = !_siempreArriba;
    await windowManager.setAlwaysOnTop(_siempreArriba);
    setState(() {});
  }

  String _fechaCorta() {
    final ahora = DateTime.now();
    const dias = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    const meses = ['Ene','Feb','Mar','Abr','May','Jun',
        'Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${dias[ahora.weekday - 1]} ${ahora.day} ${meses[ahora.month - 1]}';
  }

  void _mostrarResumenSemanal(BuildContext context, AgendaEstado estado) {
    final resumen = estado.resumenProxima7Dias();
    final colors = Theme.of(context).colorScheme;
    final diasSemana = CalendarioI18n.diasAbrev3(estado.idioma);
    final meses = CalendarioI18n.mesesAbrev(estado.idioma)
        .map((m) => m.toLowerCase()).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, minWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 ${estado.t('principal.proximos_7_dias')}',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (resumen.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                        child: Text('🎉 ${estado.t('principal.nada_pendiente_semana')}',
                            textAlign: TextAlign.center)),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.6),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: resumen.entries.map((e) {
                          final p = e.key.split('-');
                          final dia = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                          final label =
                              '${diasSemana[dia.weekday - 1]} ${dia.day} ${meses[dia.month - 1]}';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(label,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: colors.onPrimaryContainer)),
                              ),
                              ...e.value.citas.map((c) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, bottom: 2),
                                    child: Row(children: [
                                      Text('📅 ${c.hora}  ',
                                          style: TextStyle(
                                              fontSize: 12, color: colors.primary,
                                              fontWeight: FontWeight.bold)),
                                      Expanded(
                                          child: Text(c.descripcion,
                                              style: const TextStyle(fontSize: 12))),
                                    ]),
                                  )),
                              ...e.value.tareas.map((t) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8, bottom: 2),
                                    child: Row(children: [
                                      const Text('● ',
                                          style: TextStyle(fontSize: 12)),
                                      Expanded(
                                          child: Text(t.titulo,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  decoration: t.completada
                                                      ? TextDecoration.lineThrough
                                                      : null))),
                                    ]),
                                  )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(estado.t('comun.cerrar'))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarKanban(BuildContext context, AgendaEstado estado) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SeccionKanban(esPopup: true)));
  }

  Future<void> _sincronizarManual(AgendaEstado estado) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final cred = await ClienteNube.leerCredenciales();
      if (cred.token == null || cred.gistId == null ||
          cred.token!.isEmpty || cred.gistId!.isEmpty) {
        messenger.showSnackBar(
            SnackBar(content: Text('⚠️ ${estado.t('principal.sync_configura_github')}')));
        return;
      }
      final cliente = ClienteNube(token: cred.token!, gistId: cred.gistId!);

      // 1. Bajar de la nube
      messenger.showSnackBar(
          SnackBar(content: Text('⬇️ ${estado.t('principal.sync_descargando')}'), duration: const Duration(seconds: 1)));
      final resultado = await cliente.descargar();
      final jsonNube = resultado.contenido;
      final tsNube = resultado.fechaModificacion;

      // 2. Comparar con lo local
      final jsonLocal = estado.exportarAJsonSync();
      final nubeLen = jsonNube.length;

      // 3. Si la nube tiene datos y es diferente, importar
      if (tsNube > 0 && jsonNube != jsonLocal) {
        await estado.importarDeJson(jsonNube);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text('⬇️ ${estado.t('principal.sync_descargado').replaceAll('{kb}', (nubeLen / 1024).toStringAsFixed(1))}'),
          duration: const Duration(seconds: 2),
        ));
      }

      // 4. Subir lo local (puede tener cambios nuevos post-import)
      final jsonSubir = estado.exportarAJsonSync();
      await cliente.subir(jsonSubir);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('⬆️ ${estado.t('principal.sync_subido').replaceAll('{kb}', (jsonSubir.length / 1024).toStringAsFixed(1))}'),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('❌ ${estado.t('principal.sync_error').replaceAll('{error}', '$e')}')));
    }
  }

  // ═══════════════════════════════════════════
  // SECCIÓN CITAS (filtrada por período)
  // ═══════════════════════════════════════════

  Widget _buildSeccionCitas(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    var proximas = estado.citasProximas;
    if (_filtro != FiltroPeriodo.todo) {
      proximas = proximas.where((c) => _pasaFiltro(c.fecha)).toList();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.primaryContainer,
            child: Row(
              children: [
                Text('📅 ${estado.t('principal.citas_proximas')}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer)),
                const Spacer(),
                Text('${proximas.length}',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            colors.onPrimaryContainer.withValues(alpha: 0.7))),
              ],
            ),
          ),
          if (proximas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(estado.t('principal.no_hay_citas_proximas'),
                      style: const TextStyle(color: Colors.grey))),
            )
          else
            ...proximas.map((cita) {
              final globalIdx = estado.citas.indexOf(cita);
              final etiqueta = estado.buscarEtiqueta(cita.etiqueta);
              final esHoy = _esFechaHoy(cita.fecha);
              final partes = cita.fecha.split('-');
              final fechaCorta = '${partes[2]}/${partes[1]}';
              return Container(
                decoration: esHoy
                    ? BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: 0.3),
                        border: Border(
                            left: BorderSide(color: colors.error, width: 3)))
                    : null,
                child: ListTile(
                  dense: true,
                  leading: esHoy
                      ? CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.error.withValues(alpha: 0.15),
                          child: const Text('⚠️',
                              style: TextStyle(fontSize: 14)))
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.primaryContainer,
                          child: Text(fechaCorta,
                              style: TextStyle(
                                  fontSize: 9, color: colors.primary))),
                  title: Text(cita.descripcion,
                      style: TextStyle(
                          fontWeight: esHoy ? FontWeight.bold : null)),
                  subtitle: Row(
                    children: [
                      Text('🕐 ${cita.hora}'),
                      if (esHoy) ...[
                        const SizedBox(width: 6),
                        Text('⚠️ HOY',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.error)),
                      ],
                      if (etiqueta != null) ...[
                        const SizedBox(width: 6),
                        Text('${etiqueta.emoji} ${etiqueta.nombre}',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'editar', child: Text('✏️ ${estado.t('comun.editar')}')),
                      PopupMenuItem(
                          value: 'eliminar', child: Text('🗑️ ${estado.t('comun.eliminar')}')),
                    ],
                    onSelected: (v) async {
                      if (v == 'editar') {
                        final editada = await showDialog<Cita>(
                          context: context,
                          builder: (_) => DialogoCita(citaExistente: cita),
                        );
                        if (editada != null && globalIdx >= 0) {
                          await estado.editarCita(globalIdx, editada);
                        }
                      } else if (v == 'eliminar' && globalIdx >= 0) {
                        await estado.eliminarCita(globalIdx);
                      }
                    },
                  ),
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final cita = await showDialog<Cita>(
                      context: context,
                      builder: (_) => const DialogoCita(),
                    );
                    if (cita != null) await estado.agregarCita(cita);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(estado.t('principal.anadir_cita')),
                ),
                TextButton.icon(
                  onPressed: () => _crearCitaPeriodica(context, estado),
                  icon: const Icon(Icons.repeat, size: 18),
                  label: Text(estado.t('principal.periodica')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearCitaPeriodica(
      BuildContext context, AgendaEstado estado) async {
    final citas = await showDialog<List<Cita>>(
      context: context,
      builder: (_) => const DialogoCitaPeriodica(),
    );
    if (citas == null || citas.isEmpty) return;
    for (final c in citas) {
      await estado.agregarCita(c);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${estado.t('principal.citas_creadas').replaceAll('{n}', '${citas.length}')}')),
    );
  }

  // ═══════════════════════════════════════════
  // SECCIÓN LISTAS
  // ═══════════════════════════════════════════

  Widget _buildSeccionListas(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    if (estado.listasPersonalizadas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: TextButton.icon(
              onPressed: () => _crearLista(context, estado),
              icon: const Icon(Icons.add),
              label: Text(estado.t('principal.crear_primera_lista')),
            ),
          ),
        ),
      );
    }
    return Column(
      children: List.generate(estado.listasPersonalizadas.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSeccionLista(
              context, estado, estado.listasPersonalizadas[i], i, colors),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════
  // SECCIÓN TAREAS CRÍTICAS (filtrada por período)
  // ═══════════════════════════════════════════

  Widget _buildSeccionCriticas(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    final tareasFiltradas = _filtrarTareas(estado.tareasCriticas);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.errorContainer,
            child: Row(
              children: [
                Text('🚨 ${estado.t('principal.tareas_criticas')}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onErrorContainer)),
                const Spacer(),
                Text(
                  '${tareasFiltradas.where((t) => t.estado != 'completada').length} ${estado.t('principal.pendientes_sufijo')}',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          colors.onErrorContainer.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          if (tareasFiltradas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(
                _filtro == FiltroPeriodo.todo
                    ? estado.t('principal.no_hay_tareas_criticas')
                    : estado.t('principal.sin_tareas_periodo'),
                style: const TextStyle(color: Colors.grey),
              )),
            )
          else
            ...tareasFiltradas.map((tarea) {
              final index = estado.tareasCriticas.indexOf(tarea);
              return TarjetaTarea(
                tarea: tarea,
                index: index,
                onCambiarEstado: () => estado.cambiarEstadoTareaCritica(
                    index, siguienteEstado(tarea.estado)),
                onCambiarEstadoConDatos: (nuevoEstado, {persona, fecha}) =>
                    estado.cambiarEstadoCriticaConDatos(
                        index, nuevoEstado, persona: persona, fecha: fecha),
                onEditar: () =>
                    _editarTareaCritica(context, estado, index, tarea),
                onEliminar: () => _confirmarEliminar(
                    context, () => estado.eliminarTareaCritica(index)),
                onAgregarSubtarea: () =>
                    _agregarSubtareaCritica(context, estado, index),
                onCambiarEstadoSubtarea: (si) =>
                    estado.cambiarEstadoSubtareaCritica(index, si,
                        siguienteEstado(tarea.subtareas[si].estado)),
                onEliminarSubtarea: (si) => _confirmarEliminar(
                    context,
                    () => estado.eliminarSubtareaCritica(index, si)),
              );
            }),
          _buildBotonesCrearTarea(context, estado, 'criticas'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SECCIÓN LISTA PERSONALIZADA (filtrada por período)
  // ═══════════════════════════════════════════

  Widget _buildSeccionLista(BuildContext context, AgendaEstado estado,
      ListaPersonalizada lista, int listaIndex, ColorScheme colors) {
    final colorLista = _parseColor(lista.color);
    final totalListas = estado.listasPersonalizadas.length;
    final tareasFiltradas = _filtrarTareas(lista.tareas);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorLista.withValues(alpha: 0.2),
            child: Row(
              children: [
                if (totalListas > 1) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: estado.t('comun.subir_tooltip'),
                    onPressed: listaIndex > 0
                        ? () => estado.moverLista(listaIndex, listaIndex - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: estado.t('comun.bajar_tooltip'),
                    onPressed: listaIndex < totalListas - 1
                        ? () => estado.moverLista(listaIndex, listaIndex + 1)
                        : null,
                  ),
                ],
                Expanded(
                  child: Text('${lista.emoji} ${lista.nombre}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface)),
                ),
                Text(
                  '${tareasFiltradas.where((t) => t.estado != 'completada').length}',
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.6)),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'editar', child: Text('✏️ ${estado.t('principal.editar_lista')}')),
                    PopupMenuItem(
                        value: 'eliminar',
                        child: Text('🗑️ ${estado.t('principal.eliminar_lista')}')),
                  ],
                  onSelected: (v) {
                    if (v == 'editar') _editarLista(context, estado, lista);
                    if (v == 'eliminar') {
                      _confirmarEliminar(context,
                          () => estado.eliminarLista(lista.id),
                          mensaje: estado.t('principal.confirmar_eliminar_lista')
                              .replaceAll('{nombre}', lista.nombre));
                    }
                  },
                ),
              ],
            ),
          ),
          if (tareasFiltradas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: Text(
                _filtro == FiltroPeriodo.todo
                    ? estado.t('principal.lista_vacia')
                    : estado.t('principal.sin_tareas_periodo'),
                style: const TextStyle(color: Colors.grey),
              )),
            )
          else
            ...tareasFiltradas.map((tarea) {
              final index = lista.tareas.indexOf(tarea);
              return TarjetaTarea(
                tarea: tarea,
                index: index,
                listaId: lista.id,
                onCambiarEstado: () => estado.cambiarEstadoTareaDeLista(
                    lista.id, index, siguienteEstado(tarea.estado)),
                onCambiarEstadoConDatos: (nuevoEstado, {persona, fecha}) =>
                    estado.cambiarEstadoListaConDatos(
                        lista.id, index, nuevoEstado,
                        persona: persona, fecha: fecha),
                onHacerCritica: () =>
                    estado.moverACriticas(lista.id, index),
                onEditar: () => _editarTareaDeLista(
                    context, estado, lista.id, index, tarea),
                onEliminar: () => _confirmarEliminar(context,
                    () => estado.eliminarTareaDeLista(lista.id, index)),
                onAgregarSubtarea: () =>
                    _agregarSubtareaALista(context, estado, lista.id, index),
                onCambiarEstadoSubtarea: (si) =>
                    estado.cambiarEstadoSubtareaDeLista(lista.id, index, si,
                        siguienteEstado(tarea.subtareas[si].estado)),
                onEliminarSubtarea: (si) => _confirmarEliminar(
                    context,
                    () => estado.eliminarSubtareaDeLista(
                        lista.id, index, si)),
              );
            }),
          _buildBotonesCrearTarea(context, estado, lista.id),
        ],
      ),
    );
  }

  /// Dos botones: "+ Tarea" (individual) y "📋 Plantilla" (desde plantilla).
  /// Se usan en Tareas Críticas y en cada lista personalizada.
  Widget _buildBotonesCrearTarea(
      BuildContext context, AgendaEstado estado, String destino) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: () => _crearTarea(context, estado, destinoFijo: destino),
            icon: const Icon(Icons.add, size: 18),
            label: Text(estado.t('principal.tarea_boton')),
          ),
          TextButton.icon(
            onPressed: () => estado.plantillas.isNotEmpty
                ? _elegirPlantilla(context, estado, destino)
                : _gestionarPlantillas(context, estado),
            icon: const Icon(Icons.copy_all, size: 18),
            label: Text(estado.t('principal.plantilla_boton')),
          ),
        ],
      ),
    );
  }

  /// Muestra las plantillas disponibles y crea la tarea en el destino dado.
  void _elegirPlantilla(
      BuildContext context, AgendaEstado estado, String destino) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('📋 ${estado.t('principal.crear_desde_plantilla')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ...estado.plantillas.asMap().entries.map((e) => ListTile(
                  leading: const Icon(Icons.copy_all),
                  title: Text(e.value.nombre),
                  subtitle: Text(
                      '${e.value.subtareasTexto.length} subtareas: ${e.value.subtareasTexto.take(3).join(", ")}',
                      style: const TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pedirNombreYCrearDesdePlantilla(
                        context, estado, e.key, destino);
                  },
                )),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(estado.t('principal.gestionar_plantillas')),
              onTap: () {
                Navigator.pop(ctx);
                _gestionarPlantillas(context, estado);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════

  bool _esFechaHoy(String fecha) {
    final hoy = DateTime.now();
    final hoyStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    return fecha == hoyStr;
  }

  // ═══════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════

  void _menuCrearTarea(BuildContext context, AgendaEstado estado) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(estado.t('principal.crear_tarea_titulo'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_task),
              title: Text(estado.t('principal.tarea_individual')),
              onTap: () {
                Navigator.pop(ctx);
                _crearTarea(context, estado);
              },
            ),
            ...estado.plantillas.map((p) => ListTile(
              leading: const Icon(Icons.copy_all),
              title: Text('📋 ${p.nombre}'),
              subtitle: Text('${p.subtareasTexto.length} subtareas',
                  style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _usarPlantilla(context, estado, estado.plantillas.indexOf(p));
              },
            )),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(estado.t('principal.gestionar_plantillas')),
              onTap: () {
                Navigator.pop(ctx);
                _gestionarPlantillas(context, estado);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _usarPlantilla(BuildContext context, AgendaEstado estado, int index) async {
    final listas = estado.listasPersonalizadas;
    String destino = 'criticas';
    if (listas.isNotEmpty) {
      final sel = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(estado.t('principal.donde_crear_tarea')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'criticas'),
              child: Text('🚨 ${estado.t('principal.tareas_criticas')}'),
            ),
            ...listas.map((l) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l.id),
              child: Text('${l.emoji} ${l.nombre}'),
            )),
          ],
        ),
      );
      if (sel == null) return;
      destino = sel;
    }
    await estado.usarPlantilla(index, destino: destino);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${estado.t('principal.tarea_creada_plantilla')}')),
    );
  }

  Future<void> _pedirNombreYCrearDesdePlantilla(BuildContext context,
      AgendaEstado estado, int plantillaIndex, String destino) async {
    final plantilla = estado.plantillas[plantillaIndex];
    final ctrl = TextEditingController(text: plantilla.nombre);
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(estado.t('principal.nombre_tarea_titulo')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: plantilla.nombre,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(estado.t('comun.cancelar'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(estado.t('comun.crear'))),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    await estado.usarPlantilla(plantillaIndex,
        destino: destino, nombrePersonalizado: nombre);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${estado.t('principal.tarea_creada_con_subtareas')
          .replaceAll('{nombre}', nombre)
          .replaceAll('{n}', '${plantilla.subtareasTexto.length}')}')),
    );
  }

  void _gestionarPlantillas(BuildContext context, AgendaEstado estado) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, minWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 ${estado.t('principal.gestionar_plantillas')}',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (estado.plantillas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text(estado.t('principal.sin_plantillas'),
                        style: const TextStyle(color: Colors.grey))),
                  )
                else
                  ...estado.plantillas.asMap().entries.map((e) => ListTile(
                    dense: true,
                    title: Text(e.value.nombre),
                    subtitle: Text(e.value.subtareasTexto.join(', '),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 20,
                          color: Theme.of(ctx).colorScheme.error),
                      onPressed: () {
                        estado.eliminarPlantilla(e.key);
                        Navigator.pop(ctx);
                        _gestionarPlantillas(context, estado);
                      },
                    ),
                  )),
                const Divider(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(estado.t('principal.nueva_plantilla')),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _crearPlantilla(context, estado);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(estado.t('comun.cerrar')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crearPlantilla(BuildContext context, AgendaEstado estado) async {
    final nombreCtrl = TextEditingController();
    final subtareasCtrl = TextEditingController();
    final resultado = await showDialog<PlantillaTarea>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, minWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 ${estado.t('principal.nueva_plantilla')}',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: estado.t('principal.nombre_label'),
                    hintText: estado.t('principal.nombre_hint_rutina'),
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtareasCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: estado.t('principal.subtareas_label'),
                    hintText: estado.t('principal.subtareas_hint'),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx),
                        child: Text(estado.t('comun.cancelar'))),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () {
                      final nombre = nombreCtrl.text.trim();
                      if (nombre.isEmpty) return;
                      final subs = subtareasCtrl.text
                          .split('\n').map((s) => s.trim())
                          .where((s) => s.isNotEmpty).toList();
                      Navigator.pop(ctx, PlantillaTarea(
                          nombre: nombre, subtareasTexto: subs));
                    }, child: Text(estado.t('comun.crear'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (resultado != null) await estado.agregarPlantilla(resultado);
  }

  Future<void> _crearTarea(BuildContext context, AgendaEstado estado,
      {String? destinoFijo}) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => DialogoTarea(destinoInicial: destinoFijo),
    );
    if (r == null) return;
    final tarea = r['tarea'] as Tarea;
    final destino = destinoFijo ?? r['destino'] as String;
    if (destino == 'criticas') {
      await estado.agregarTareaCritica(tarea);
    } else {
      await estado.agregarTareaALista(destino, tarea);
    }
  }

  Future<void> _editarTareaCritica(BuildContext context, AgendaEstado estado,
      int index, Tarea tarea) async {
    final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => DialogoTarea(
            tareaExistente: tarea, destinoInicial: 'criticas'));
    if (r != null) {
      await estado.editarTareaCritica(index, r['tarea'] as Tarea);
    }
  }

  Future<void> _editarTareaDeLista(BuildContext context, AgendaEstado estado,
      String listaId, int index, Tarea tarea) async {
    final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) =>
            DialogoTarea(tareaExistente: tarea, destinoInicial: listaId));
    if (r != null) {
      await estado.editarTareaDeLista(listaId, index, r['tarea'] as Tarea);
    }
  }

  Future<void> _agregarSubtareaCritica(
      BuildContext context, AgendaEstado estado, int idx) async {
    final sub =
        await mostrarDialogoSubtarea(context, personas: estado.personas);
    if (sub != null) await estado.agregarSubtareaCritica(idx, sub);
  }

  Future<void> _agregarSubtareaALista(BuildContext context,
      AgendaEstado estado, String listaId, int idx) async {
    final sub =
        await mostrarDialogoSubtarea(context, personas: estado.personas);
    if (sub != null) await estado.agregarSubtareaALista(listaId, idx, sub);
  }

  Future<void> _crearLista(BuildContext context, AgendaEstado estado) async {
    final lista = await showDialog<ListaPersonalizada>(
        context: context, builder: (_) => const DialogoLista());
    if (lista != null) await estado.agregarLista(lista);
  }

  Future<void> _editarLista(BuildContext context, AgendaEstado estado,
      ListaPersonalizada lista) async {
    final editada = await showDialog<ListaPersonalizada>(
        context: context,
        builder: (_) => DialogoLista(listaExistente: lista));
    if (editada != null) await estado.editarLista(lista.id, editada);
  }

  Future<void> _confirmarEliminar(BuildContext context, VoidCallback onOk,
      {String? mensaje}) async {
    final estado = context.read<AgendaEstado>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(estado.t('principal.confirmar_titulo')),
        content: Text(mensaje ?? estado.t('principal.confirmar_eliminar_generico')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(estado.t('comun.cancelar'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(estado.t('comun.eliminar')),
          ),
        ],
      ),
    );
    if (ok == true) onOk();
  }

  Widget _buildIndicadorSync(EstadoSync estadoSync) {
    final estado = context.read<AgendaEstado>();
    switch (estadoSync) {
      case EstadoSync.subiendo:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
        );
      case EstadoSync.sincronizado:
        return Tooltip(
          message: estado.t('principal.sync_indicador').replaceAll('{texto}', estado.ultimaSyncTexto),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.cloud_done, size: 20, color: Colors.green),
          ),
        );
      case EstadoSync.pendiente:
        return Tooltip(
          message: estado.t('principal.cambios_pendientes'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.cloud_upload, size: 20, color: Colors.orange),
          ),
        );
      case EstadoSync.error:
        return Tooltip(
          message: estado.t('principal.error_sincronizacion'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.cloud_off, size: 20, color: Colors.red),
          ),
        );
      case EstadoSync.sinConexion:
        return Tooltip(
          message: estado.t('principal.sin_conexion'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.wifi_off, size: 20, color: Colors.grey),
          ),
        );
      case EstadoSync.desactivado:
        return const SizedBox.shrink();
    }
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
