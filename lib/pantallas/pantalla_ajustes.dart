import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/etiqueta.dart';
import '../modelos/configuracion.dart';
import '../repositorios/almacenamiento_sqlite.dart';
import '../servicios/cliente_nube.dart';
import '../servicios/servicio_notificaciones.dart';
import '../i18n/idioma.dart';
import '../i18n/traducciones.dart';

/// Pantalla de ajustes: etiquetas, personas, título y tema.
/// Equivale a las pestañas de configuración del modal-config de la app web.
class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('⚙️ ${estado.t('ajustes.titulo')}'),
        backgroundColor: colors.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ APARIENCIA ═══
          _buildSeccionTitulo('🎨 ${estado.t('ajustes.apariencia')}', colors),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Idioma
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(estado.t('idioma.titulo')),
                    trailing: DropdownButton<Idioma>(
                      value: estado.idioma,
                      underline: const SizedBox(),
                      items: Idioma.values
                          .map((i) => DropdownMenuItem(
                                value: i,
                                child: Text(i.nombreNativo),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) estado.cambiarIdioma(v);
                      },
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(estado.t('ajustes.modo_oscuro')),
                    subtitle: Text(estado.t('ajustes.modo_oscuro_sub')),
                    secondary: Icon(
                      estado.modoOscuro ? Icons.dark_mode : Icons.light_mode,
                    ),
                    value: estado.modoOscuro,
                    onChanged: (v) => estado.cambiarModoOscuro(v),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.title),
                    title: Text(estado.t('ajustes.titulo_agenda')),
                    subtitle: Text(estado.titulo),
                    onTap: () => _editarTitulo(context, estado),
                  ),
                  const Divider(),

                  // Paleta de color
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(estado.t('ajustes.paleta_color')),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: paletasDisponibles.entries.map((e) {
                        final seleccionada = estado.paleta == e.key;
                        return ChoiceChip(
                          label: Text(nombrePaleta(e.key, estado.idioma)),
                          selected: seleccionada,
                          selectedColor:
                              Color(e.value.seedColor).withValues(alpha: 0.3),
                          onSelected: (_) =>
                              estado.cambiarPaleta(e.key),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 24),

                  // Número de columnas
                  ListTile(
                    leading: const Icon(Icons.view_column),
                    title: Text(estado.t('ajustes.columnas_layout')),
                    subtitle: Text('${estado.columnas} ${estado.columnas > 1 ? estado.t('ajustes.columna_plural') : estado.t('ajustes.columna_singular')}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1'), icon: Icon(Icons.view_agenda)),
                        ButtonSegment(value: 2, label: Text('2'), icon: Icon(Icons.view_column_outlined)),
                        ButtonSegment(value: 3, label: Text('3'), icon: Icon(Icons.grid_view)),
                      ],
                      selected: {estado.columnas},
                      onSelectionChanged: (s) =>
                          estado.cambiarColumnas(s.first),
                    ),
                  ),
                  const Divider(height: 24),

                  // Resumen diario
                  SwitchListTile(
                    title: Text('📋 ${estado.t('ajustes.resumen_diario')}'),
                    subtitle: Text(estado.t('ajustes.resumen_diario_sub')),
                    value: estado.configuracion.resumenDiario,
                    onChanged: (v) => estado.cambiarResumenDiario(v),
                  ),
                  const Divider(height: 24),

                  // Tamaño de letra
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: Text(estado.t('ajustes.tamano_letra')),
                    subtitle: Text('${estado.tamanoLetra.round()}'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Slider(
                    value: estado.tamanoLetra,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    label: '${estado.tamanoLetra.round()}',
                    onChanged: (v) => estado.cambiarTamanoLetra(v),
                  ),
                  const Divider(height: 24),

                  // Icono de la app
                  ListTile(
                    leading: const Icon(Icons.emoji_emotions),
                    title: Text(estado.t('ajustes.icono_agenda')),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      '📋', '📝', '📚', '📅', '🎯', '⚡', '🚀', '🌟',
                      '💡', '🔥', '💪', '🧠', '🏆', '😊', '🎉', '📊',
                      '🗓️', '✅', '🌈', '💼',
                    ].map((e) => ChoiceChip(
                          label: Text(e, style: const TextStyle(fontSize: 20)),
                          selected: estado.iconoApp == e,
                          onSelected: (_) => estado.cambiarIconoApp(e),
                        )).toList(),
                  ),
                  const Divider(height: 24),

                  // Frases motivacionales
                  ListTile(
                    leading: const Icon(Icons.format_quote),
                    title: Text(estado.t('ajustes.frases_motivacionales')),
                    subtitle: Text(estado.t('ajustes.frases_motivacionales_sub')),
                    contentPadding: EdgeInsets.zero,
                  ),
                  _CampoFrases(
                    frasesActuales: estado.frases,
                    onGuardar: (f) => estado.cambiarFrases(f),
                    estado: estado,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ═══ DISTRIBUCIÓN DE SECCIONES ═══
          _buildSeccionTitulo('📐 ${estado.t('ajustes.orden_secciones')}', colors),
          _EditorDistribucion(
            columnas: estado.columnas,
            distribucionActual: estado.distribucion,
            onCambiar: (d) => estado.cambiarDistribucion(d),
            idioma: estado.idioma,
          ),
          const SizedBox(height: 24),

          // ═══ ETIQUETAS ═══
          _buildSeccionTitulo('🏷️ ${estado.t('ajustes.etiquetas_tareas')}', colors),
          _buildListaEtiquetas(context, estado, colors),
          const SizedBox(height: 8),
          _buildFormularioNuevaEtiqueta(context, estado),
          const SizedBox(height: 24),

          // ═══ PERSONAS ═══
          _buildSeccionTitulo('👥 ${estado.t('ajustes.personas')}', colors),
          _buildListaPersonas(context, estado, colors),
          const SizedBox(height: 8),
          _buildFormularioNuevaPersona(context, estado),
          const SizedBox(height: 24),

          // ═══ NOTIFICACIONES ═══
          _buildSeccionTitulo('🔔 ${estado.t('ajustes.notificaciones')}', colors),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estado.t('ajustes.notif_cuando_avisar'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    (min: 15, label: estado.t('ajustes.notif_15min')),
                    (min: 60, label: estado.t('ajustes.notif_1h')),
                    (min: 1440, label: estado.t('ajustes.notif_1dia')),
                  ].map((op) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(op.label),
                        value: estado.configuracion.recordatoriosPorDefecto
                            .contains(op.min),
                        onChanged: (v) {
                          final lista = List<int>.from(
                              estado.configuracion.recordatoriosPorDefecto);
                          if (v == true) {
                            lista.add(op.min);
                          } else {
                            lista.remove(op.min);
                          }
                          estado.cambiarRecordatoriosPorDefecto(lista);
                        },
                      )),
                  const SizedBox(height: 4),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      try {
                        await ServicioNotificaciones.inicializar();
                        await ServicioNotificaciones.reprogramarTodas(
                            estado.citas);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '✅ ${estado.t('ajustes.notif_reprogramadas').replaceAll('{n}', '${estado.citas.length}')}')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_active),
                    label: Text(estado.t('ajustes.reprogramar_notif')),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      try {
                        await ServicioNotificaciones.inicializar();
                        await ServicioNotificaciones.enviarPrueba();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ ${estado.t('ajustes.notif_enviada')}')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: Text(estado.t('ajustes.enviar_prueba')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ═══ WIDGET DE PANTALLA DE INICIO (solo Android) ═══
          if (Platform.isAndroid) ...[
            _buildSeccionTitulo('📱 ${estado.t('ajustes.widget_inicio')}', colors),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        estado.t('ajustes.widget_elegir'),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    SwitchListTile(
                      title: Text('🔴 ${estado.t('ajustes.widget_tareas_criticas')}'),
                      value: estado.widgetMostrarCriticas,
                      onChanged: (v) => estado.cambiarWidgetMostrarCriticas(v),
                    ),
                    SwitchListTile(
                      title: Text('🕐 ${estado.t('ajustes.widget_proximas_citas')}'),
                      value: estado.widgetMostrarCitas,
                      onChanged: (v) => estado.cambiarWidgetMostrarCitas(v),
                    ),
                    SwitchListTile(
                      title: Text('● ${estado.t('ajustes.widget_tareas_hoy')}'),
                      value: estado.widgetMostrarHoy,
                      onChanged: (v) => estado.cambiarWidgetMostrarHoy(v),
                    ),
                    SwitchListTile(
                      title: Text('📋 ${estado.t('ajustes.widget_listas_personales')}'),
                      value: estado.widgetMostrarListas,
                      onChanged: (v) => estado.cambiarWidgetMostrarListas(v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ═══ DISPOSITIVO ═══
          _buildSeccionTitulo('💾 ${estado.t('ajustes.dispositivo')}', colors),
          _WidgetDispositivo(
            nombreDispositivo: estado.dispositivoNombre,
            onCambiarNombre: (n) => estado.cambiarDispositivoNombre(n),
            onCambiarRuta: (r) => estado.cambiarRutaDb(r),
            estado: estado,
          ),
          const SizedBox(height: 24),

          // ═══ SINCRONIZACIÓN EN LA NUBE ═══
          _buildSeccionTitulo('☁️ ${estado.t('ajustes.sincronizacion')}', colors),
          _WidgetSyncNube(estado: estado),
        ],
      ),
    );
  }


  Widget _buildSeccionTitulo(String titulo, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EDITAR TÍTULO
  // ═══════════════════════════════════════════

  Future<void> _editarTitulo(
      BuildContext context, AgendaEstado estado) async {
    final ctrl = TextEditingController(text: estado.titulo);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(estado.t('ajustes.titulo_agenda')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: estado.t('ajustes.titulo_agenda_hint'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(estado.t('comun.cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(estado.t('comun.guardar')),
          ),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      await estado.cambiarTitulo(resultado);
    }
  }

  // ═══════════════════════════════════════════
  // ETIQUETAS
  // ═══════════════════════════════════════════

  Widget _buildListaEtiquetas(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    final etiquetas = estado.etiquetasTareas;

    if (etiquetas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              estado.t('ajustes.no_hay_etiquetas'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: List.generate(etiquetas.length, (index) {
          final et = etiquetas[index];
          final globalIndex = estado.etiquetas.indexOf(et);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _parseColor(et.color),
              child: Text(et.emoji, style: const TextStyle(fontSize: 18)),
            ),
            title: Text(et.nombre),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(estado.t('ajustes.eliminar_etiqueta_titulo')),
                    content: Text(estado.t('ajustes.eliminar_etiqueta_contenido')
                        .replaceAll('{nombre}', et.nombre)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(estado.t('comun.cancelar')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(estado.t('comun.eliminar')),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await estado.eliminarEtiqueta(globalIndex);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormularioNuevaEtiqueta(
      BuildContext context, AgendaEstado estado) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _FormularioEtiqueta(
          onGuardar: (etiqueta) => estado.agregarEtiqueta(etiqueta),
          estado: estado,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PERSONAS
  // ═══════════════════════════════════════════

  Widget _buildListaPersonas(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    if (estado.personas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              estado.t('ajustes.no_hay_personas'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: List.generate(estado.personas.length, (index) {
          return ListTile(
            leading: const CircleAvatar(child: Text('👤')),
            title: Text(estado.personas[index]),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              onPressed: () => estado.eliminarPersona(index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormularioNuevaPersona(
      BuildContext context, AgendaEstado estado) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _FormularioPersona(
          onGuardar: (nombre) => estado.agregarPersona(nombre),
          estado: estado,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

// ═══════════════════════════════════════════
// FORMULARIOS STATEFUL (necesitan su propio estado local)
// ═══════════════════════════════════════════

/// Formulario para crear una etiqueta nueva.
/// Es StatefulWidget porque maneja inputs locales que no afectan
/// al estado global hasta que se pulse "Añadir".
class _FormularioEtiqueta extends StatefulWidget {
  final Function(Etiqueta) onGuardar;
  final AgendaEstado estado;

  const _FormularioEtiqueta({required this.onGuardar, required this.estado});

  @override
  State<_FormularioEtiqueta> createState() => _FormularioEtiquetaState();
}

class _FormularioEtiquetaState extends State<_FormularioEtiqueta> {
  final _nombreCtrl = TextEditingController();
  String _emoji = '📌';
  String _color = '#4ecdc4';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nombreCtrl,
          decoration: InputDecoration(
            labelText: widget.estado.t('ajustes.nombre_etiqueta'),
            hintText: widget.estado.t('ajustes.nombre_etiqueta_hint'),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        Text(widget.estado.t('ajustes.emoji_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: emojisDisponibles
              .map((e) => ChoiceChip(
                    label: Text(e),
                    selected: _emoji == e,
                    onSelected: (_) => setState(() => _emoji = e),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(widget.estado.t('ajustes.color_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: coloresDisponibles
              .map((c) => GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _parseColor(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _color == c
                            ? [
                                BoxShadow(
                                  color: _parseColor(c).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              final nombre = _nombreCtrl.text.trim();
              if (nombre.isEmpty) return;
              widget.onGuardar(Etiqueta(
                nombre: nombre,
                emoji: _emoji,
                color: _color,
                tipo: 'tareas',
              ));
              _nombreCtrl.clear();
              setState(() {
                _emoji = '📌';
                _color = '#4ecdc4';
              });
            },
            icon: const Icon(Icons.add),
            label: Text(widget.estado.t('ajustes.anadir_etiqueta')),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

/// Formulario para añadir una persona nueva.
class _FormularioPersona extends StatefulWidget {
  final Function(String) onGuardar;
  final AgendaEstado estado;

  const _FormularioPersona({required this.onGuardar, required this.estado});

  @override
  State<_FormularioPersona> createState() => _FormularioPersonaState();
}

class _FormularioPersonaState extends State<_FormularioPersona> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: widget.estado.t('ajustes.nombre_persona'),
              hintText: widget.estado.t('ajustes.nombre_persona_hint'),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _agregar(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _agregar,
          icon: const Icon(Icons.person_add),
          label: Text(widget.estado.t('comun.anadir')),
        ),
      ],
    );
  }

  void _agregar() {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;
    widget.onGuardar(nombre);
    _ctrl.clear();
  }
}

/// Formulario para configurar la ruta completa de la BD SQLite.
/// Permite elegir carpeta con el explorador y nombre del fichero.
/// Widget simple: muestra dispositivo + ruta BD en una Card compacta.
/// "DESKTOP-D2NIO4G  —  C:\...\agenda.db  [📁] [✏️]"
class _WidgetDispositivo extends StatefulWidget {
  final String nombreDispositivo;
  final Function(String) onCambiarNombre;
  final Function(String?) onCambiarRuta;
  final AgendaEstado estado;

  const _WidgetDispositivo({
    required this.nombreDispositivo,
    required this.onCambiarNombre,
    required this.onCambiarRuta,
    required this.estado,
  });

  @override
  State<_WidgetDispositivo> createState() => _WidgetDispositivoState();
}

class _WidgetDispositivoState extends State<_WidgetDispositivo> {
  String? _rutaActual;

  @override
  void initState() {
    super.initState();
    AlmacenamientoSqlite.leerRutaLocal().then((ruta) {
      if (mounted) setState(() => _rutaActual = ruta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rutaMostrar = _rutaActual ?? widget.estado.t('ajustes.ubicacion_defecto');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila dispositivo: nombre editable
            Row(
              children: [
                const Icon(Icons.devices, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _editarNombre,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: widget.nombreDispositivo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      TextSpan(
                          text: '  ✏️',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.primary)),
                    ])),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fila BD: ruta + botón cambiar
            Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rutaMostrar,
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _seleccionarDb,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(widget.estado.t('ajustes.cambiar')),
                ),
                if (_rutaActual != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.restore, size: 18),
                    tooltip: widget.estado.t('ajustes.usar_ubicacion_defecto_tooltip'),
                    onPressed: () {
                      widget.onCambiarRuta(null);
                      setState(() => _rutaActual = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(widget.estado.t('ajustes.reinicia_para_aplicar'))),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarNombre() async {
    final ctrl = TextEditingController(text: widget.nombreDispositivo);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.estado.t('ajustes.nombre_dispositivo_titulo')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: widget.estado.t('ajustes.nombre_dispositivo_hint'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(widget.estado.t('comun.cancelar'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(widget.estado.t('comun.guardar'))),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      widget.onCambiarNombre(resultado);
    }
  }

  Future<void> _seleccionarDb() async {
    final ctrl = TextEditingController(text: _rutaActual ?? '');
    final rutaCompleta = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.estado.t('ajustes.ruta_bd_titulo')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.estado.t('ajustes.ruta_bd_hint'),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(widget.estado.t('comun.cancelar'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(widget.estado.t('comun.guardar'))),
        ],
      ),
    );
    if (rutaCompleta == null || rutaCompleta.isEmpty) return;

    widget.onCambiarRuta(rutaCompleta);
    setState(() => _rutaActual = rutaCompleta);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.estado.t('ajustes.bd_reinicia').replaceAll('{ruta}', rutaCompleta))),
    );
  }
}

/// Editor de distribución: reordenar secciones + asignar ubicación
/// (ancho completo, columna 1/2/3, u oculta).
/// Campo de texto para editar las frases motivacionales (una por línea).
class _CampoFrases extends StatefulWidget {
  final String frasesActuales;
  final Function(String) onGuardar;
  final AgendaEstado estado;

  const _CampoFrases({required this.frasesActuales, required this.onGuardar, required this.estado});

  @override
  State<_CampoFrases> createState() => _CampoFrasesState();
}

class _CampoFrasesState extends State<_CampoFrases> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.frasesActuales);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 6,
          minLines: 3,
          decoration: InputDecoration(
            hintText: widget.estado.t('ajustes.frases_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            widget.onGuardar(_ctrl.text);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.estado.t('ajustes.frases_guardadas')), duration: const Duration(seconds: 1)),
            );
          },
          child: Text(widget.estado.t('ajustes.guardar_frases')),
        ),
      ],
    );
  }
}

/// Widget de sincronización con JSONBin.io.
/// Permite configurar credenciales, crear bin, y subir/bajar manualmente.
class _WidgetSyncNube extends StatefulWidget {
  final AgendaEstado estado;
  const _WidgetSyncNube({required this.estado});

  @override
  State<_WidgetSyncNube> createState() => _WidgetSyncNubeState();
}

class _WidgetSyncNubeState extends State<_WidgetSyncNube> {
  final _tokenCtrl = TextEditingController();
  final _gistIdCtrl = TextEditingController();
  bool _cargando = false;
  String? _mensaje;
  bool _configurado = false;

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  Future<void> _cargarCredenciales() async {
    final cred = await ClienteNube.leerCredenciales();
    if (mounted) {
      setState(() {
        _tokenCtrl.text = cred.token ?? '';
        _gistIdCtrl.text = cred.gistId ?? '';
        _configurado =
            (cred.token ?? '').isNotEmpty && (cred.gistId ?? '').isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _gistIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_configurado) ...[
              Text(widget.estado.t('ajustes.config_github'),
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: colors.onSurface)),
              const SizedBox(height: 4),
              Text(
                widget.estado.t('ajustes.pasos_github'),
                style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 12),
            ],

            // Token
            TextField(
              controller: _tokenCtrl,
              decoration: InputDecoration(
                labelText: widget.estado.t('ajustes.token_label'),
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.key, size: 20),
              ),
              obscureText: true,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Gist ID
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gistIdCtrl,
                    decoration: InputDecoration(
                      labelText: widget.estado.t('ajustes.gist_id_label'),
                      hintText: widget.estado.t('ajustes.gist_id_hint'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.cloud, size: 20),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _cargando ? null : _crearGist,
                  child: _cargando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.estado.t('ajustes.crear_gist')),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _cargando ? null : _guardarCredenciales,
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(widget.estado.t('comun.guardar')),
                ),
                OutlinedButton.icon(
                  onPressed: _exportarCredenciales,
                  icon: const Icon(Icons.upload, size: 18),
                  label: Text(widget.estado.t('ajustes.exportar')),
                ),
                OutlinedButton.icon(
                  onPressed: _importarCredenciales,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(widget.estado.t('ajustes.importar')),
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (_configurado) ...[
              const Divider(),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _cargando ? null : _subirManual,
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: Text(widget.estado.t('ajustes.subir_nube')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _cargando ? null : _bajarManual,
                    icon: const Icon(Icons.cloud_download, size: 18),
                    label: Text(widget.estado.t('ajustes.bajar_nube')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _cargando ? null : _diagnostico,
                    icon: const Icon(Icons.bug_report, size: 18),
                    label: Text(widget.estado.t('ajustes.diagnostico')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _cargando ? null : _verHistorial,
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(widget.estado.t('ajustes.historial')),
                  ),
                ],
              ),
            ],

            if (_mensaje != null) ...[
              const SizedBox(height: 8),
              Text(_mensaje!,
                  style: TextStyle(
                      fontSize: 12,
                      color: _mensaje!.startsWith('✅')
                          ? Colors.green
                          : _mensaje!.startsWith('❌')
                              ? colors.error
                              : colors.onSurface)),
            ],
            if (_cargando) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _crearGist() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _mensaje = '❌ ${widget.estado.t('ajustes.pega_token')}');
      return;
    }
    setState(() { _cargando = true; _mensaje = null; });
    try {
      final gistId = await ClienteNube.crearGist(token);
      _gistIdCtrl.text = gistId;
      await ClienteNube.guardarCredenciales(token: token, gistId: gistId);
      setState(() {
        _configurado = true;
        _mensaje = '✅ ${widget.estado.t('ajustes.gist_creado').replaceAll('{id}', gistId)}';
      });
    } catch (e) {
      setState(() => _mensaje = '❌ $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCredenciales() async {
    final token = _tokenCtrl.text.trim();
    final gistId = _gistIdCtrl.text.trim();
    if (token.isEmpty || gistId.isEmpty) {
      setState(() => _mensaje = '❌ ${widget.estado.t('ajustes.rellena_token_gist')}');
      return;
    }
    await ClienteNube.guardarCredenciales(token: token, gistId: gistId);
    setState(() {
      _configurado = true;
      _mensaje = '✅ ${widget.estado.t('ajustes.credenciales_guardadas')}';
    });
  }

  Future<void> _exportarCredenciales() async {
    final cred = await ClienteNube.leerCredenciales();
    if (cred.token == null || cred.gistId == null) {
      setState(() => _mensaje = '❌ ${widget.estado.t('ajustes.no_hay_credenciales')}');
      return;
    }
    final texto = '${cred.token}\n${cred.gistId}';
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    setState(() => _mensaje = '✅ ${widget.estado.t('ajustes.credenciales_copiadas')}');
  }

  Future<void> _importarCredenciales() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip == null || clip.text == null || clip.text!.trim().isEmpty) {
      setState(() => _mensaje = '❌ ${widget.estado.t('ajustes.portapapeles_vacio')}');
      return;
    }
    final lineas = clip.text!.trim().split('\n');
    if (lineas.length < 2) {
      setState(() => _mensaje = '❌ ${widget.estado.t('ajustes.formato_incorrecto')}');
      return;
    }
    final token = lineas[0].trim();
    final gistId = lineas[1].trim();
    await ClienteNube.guardarCredenciales(token: token, gistId: gistId);
    _tokenCtrl.text = token;
    _gistIdCtrl.text = gistId;
    setState(() {
      _configurado = true;
      _mensaje = '✅ ${widget.estado.t('ajustes.credenciales_importadas')}';
    });
  }

  Future<void> _subirManual() async {
    setState(() { _cargando = true; _mensaje = null; });
    try {
      final json = await widget.estado.exportarAJson();
      final cliente = ClienteNube(
          token: _tokenCtrl.text.trim(), gistId: _gistIdCtrl.text.trim());
      await cliente.subir(json);
      final kb = (json.length / 1024).toStringAsFixed(1);
      setState(() => _mensaje = '✅ ${widget.estado.t('ajustes.subido_kb').replaceAll('{kb}', kb)}');
    } catch (e) {
      setState(() => _mensaje = '❌ $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _bajarManual() async {
    setState(() { _cargando = true; _mensaje = null; });
    try {
      final cliente = ClienteNube(
          token: _tokenCtrl.text.trim(), gistId: _gistIdCtrl.text.trim());
      final resultado = await cliente.descargar();
      await widget.estado.importarDeJson(resultado.contenido);
      setState(() => _mensaje = '✅ ${widget.estado.t('ajustes.datos_descargados')}');
    } catch (e) {
      setState(() => _mensaje = '❌ $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _verHistorial() async {
    setState(() { _cargando = true; _mensaje = null; });
    try {
      final cliente = ClienteNube(
          token: _tokenCtrl.text.trim(), gistId: _gistIdCtrl.text.trim());
      final historial = await cliente.listarHistorial();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('📜 ${widget.estado.t('ajustes.historial_titulo').replaceAll('{n}', '${historial.length}')}'),
          content: SizedBox(
            width: 400,
            child: historial.isEmpty
                ? Text(widget.estado.t('ajustes.sin_historial'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: historial.length,
                    itemBuilder: (_, i) {
                      final h = historial[i];
                      final fecha =
                          '${h.fecha.day.toString().padLeft(2, '0')}/${h.fecha.month.toString().padLeft(2, '0')}/${h.fecha.year} ${h.fecha.hour.toString().padLeft(2, '0')}:${h.fecha.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        dense: true,
                        leading: Text('${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        title: Text(fecha),
                        subtitle: Text(h.version.substring(0, 8),
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              tooltip: widget.estado.t('ajustes.ver_contenido_tooltip'),
                              onPressed: () => _verContenidoVersion(ctx, cliente, h.version, fecha),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, size: 20),
                              tooltip: widget.estado.t('comun.restaurar_tooltip'),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _restaurarVersion(cliente, h.version);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(widget.estado.t('comun.cerrar'))),
          ],
        ),
      );
      setState(() => _mensaje = '✅ ${widget.estado.t('ajustes.historial_cargado')}');
    } catch (e) {
      setState(() => _mensaje = '❌ $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _verContenidoVersion(BuildContext parentCtx, ClienteNube cliente, String version, String fecha) async {
    try {
      final contenido = await cliente.descargarVersion(version);
      final json = jsonDecode(contenido) as Map<String, dynamic>;
      final d = json['datos'] as Map<String, dynamic>? ?? {};
      final origen = json['dispositivoOrigen'] ?? '?';

      final resumen = StringBuffer();
      resumen.writeln('Versión: ${version.substring(0, 8)}');
      resumen.writeln('Fecha: $fecha');
      resumen.writeln('Origen: $origen');
      resumen.writeln('');
      resumen.writeln('Tareas críticas: ${(d['tareasCriticas'] as List?)?.length ?? 0}');
      // Detalles de tareas críticas
      for (final t in (d['tareasCriticas'] as List?) ?? []) {
        resumen.writeln('  ● ${t['titulo'] ?? '?'}');
      }
      resumen.writeln('');
      resumen.writeln('Listas: ${(d['listasPersonalizadas'] as List?)?.length ?? 0}');
      for (final l in (d['listasPersonalizadas'] as List?) ?? []) {
        final tareas = (l['tareas'] as List?) ?? [];
        resumen.writeln('  📋 ${l['nombre'] ?? '?'} (${tareas.length} tareas)');
        for (final t in tareas) {
          resumen.writeln('    ● ${t['titulo'] ?? '?'}');
        }
      }
      resumen.writeln('');
      resumen.writeln('Citas: ${(d['citas'] as List?)?.length ?? 0}');
      for (final c in (d['citas'] as List?) ?? []) {
        resumen.writeln('  📅 ${c['fecha'] ?? ''} ${c['hora'] ?? ''} — ${c['descripcion'] ?? '?'}');
      }
      resumen.writeln('');
      resumen.writeln('Etiquetas: ${(d['etiquetas'] as List?)?.length ?? 0}');
      resumen.writeln('Personas: ${(d['personas'] as List?)?.length ?? 0}');
      resumen.writeln('Marcadores: ${(d['marcadores'] as List?)?.length ?? 0}');
      resumen.writeln('Notas: ${(d['notas'] as String?)?.length ?? 0} chars');

      if (!parentCtx.mounted) return;
      showDialog(
        context: parentCtx,
        builder: (ctx) => AlertDialog(
          title: Text('📄 ${widget.estado.t('ajustes.diag_version_titulo').replaceAll('{version}', version.substring(0, 8))}'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Text(resumen.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.pop(parentCtx);
                await _restaurarVersion(cliente, version);
              },
              child: Text(widget.estado.t('ajustes.restaurar_version_boton')),
            ),
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(widget.estado.t('comun.cerrar'))),
          ],
        ),
      );
    } catch (e) {
      if (!parentCtx.mounted) return;
      ScaffoldMessenger.of(parentCtx).showSnackBar(
        SnackBar(content: Text('❌ ${widget.estado.t('comun.error')}: $e')),
      );
    }
  }

  Future<void> _restaurarVersion(ClienteNube cliente, String version) async {
    setState(() { _cargando = true; _mensaje = null; });
    try {
      final contenido = await cliente.descargarVersion(version);
      await widget.estado.importarDeJson(contenido);
      setState(() => _mensaje = '✅ ${widget.estado.t('ajustes.version_restaurada')}');
    } catch (e) {
      setState(() => _mensaje = '❌ $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _diagnostico() async {
    setState(() { _cargando = true; _mensaje = null; });
    try {
      final cliente = ClienteNube(
          token: _tokenCtrl.text.trim(), gistId: _gistIdCtrl.text.trim());
      final resultado = await cliente.descargar();
      final datos = resultado.contenido;

      final json = jsonDecode(datos) as Map<String, dynamic>;
      final d = json['datos'] ?? {};
      final resumen = StringBuffer();
      resumen.writeln('=== DIAGNÓSTICO NUBE ===');
      resumen.writeln('Origen: ${json['dispositivoOrigen'] ?? '?'}');
      resumen.writeln('LastModified: ${json['lastModified'] ?? 0}');
      resumen.writeln('');
      resumen.writeln('Tareas críticas: ${(d['tareasCriticas'] as List?)?.length ?? 0}');
      resumen.writeln('Listas: ${(d['listasPersonalizadas'] as List?)?.length ?? 0}');
      resumen.writeln('Citas: ${(d['citas'] as List?)?.length ?? 0}');
      resumen.writeln('Etiquetas: ${(d['etiquetas'] as List?)?.length ?? 0}');
      resumen.writeln('Personas: ${(d['personas'] as List?)?.length ?? 0}');
      resumen.writeln('Marcadores: ${(d['marcadores'] as List?)?.length ?? 0}');
      resumen.writeln('Contrasenas: ${(d['contrasenas'] as List?)?.length ?? 0}');
      resumen.writeln('Notas: ${(d['notas'] as String?)?.length ?? 0} chars');
      resumen.writeln('');
      resumen.writeln('JSON total: ${(datos.length / 1024).toStringAsFixed(1)} KB');

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(widget.estado.t('ajustes.diagnostico')),
          content: SingleChildScrollView(
            child: Text(resumen.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(widget.estado.t('comun.cerrar'))),
          ],
        ),
      );
      setState(() => _mensaje = '✅ ${widget.estado.t('ajustes.diagnostico_completado')}');
    } catch (e) {
      setState(() => _mensaje = '❌ $e');
    } finally {
      setState(() => _cargando = false);
    }
  }
}

class _EditorDistribucion extends StatelessWidget {
  final int columnas;
  final String distribucionActual;
  final Function(String) onCambiar;
  final Idioma idioma;

  const _EditorDistribucion({
    required this.columnas,
    required this.distribucionActual,
    required this.onCambiar,
    required this.idioma,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Parsear distribución actual manteniendo el orden
    final items = _parsear();

    // Opciones disponibles para la ubicación
    final opciones = <String, String>{
      'full': Traducciones.t(idioma, 'opcion_ubicacion.completo'),
      if (columnas >= 2) '1': Traducciones.t(idioma, 'opcion_ubicacion.col1'),
      if (columnas >= 2) '2': Traducciones.t(idioma, 'opcion_ubicacion.col2'),
      if (columnas >= 3) '3': Traducciones.t(idioma, 'opcion_ubicacion.col3'),
      'hidden': Traducciones.t(idioma, 'opcion_ubicacion.oculta'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Traducciones.t(idioma, 'ajustes.orden_secciones_ayuda'),
              style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            ...List.generate(items.length, (i) {
              final item = items[i];
              final nombre = nombreSeccion(item.seccion, idioma);
              final oculta = item.ubicacion == 'hidden';

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Flechas reordenar
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24, width: 28,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_drop_up, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: i > 0
                                ? () => _mover(items, i, i - 1)
                                : null,
                          ),
                        ),
                        SizedBox(
                          height: 24, width: 28,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: i < items.length - 1
                                ? () => _mover(items, i, i + 1)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),

                    // Nombre de la sección
                    Expanded(
                      child: Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 13,
                          color: oculta
                              ? colors.onSurface.withValues(alpha: 0.4)
                              : null,
                          decoration: oculta ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),

                    // Selector de ubicación
                    DropdownButton<String>(
                      value: opciones.containsKey(item.ubicacion)
                          ? item.ubicacion
                          : 'full',
                      underline: const SizedBox(),
                      isDense: true,
                      style: TextStyle(fontSize: 12, color: colors.onSurface),
                      items: opciones.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        items[i] = (seccion: item.seccion, ubicacion: v);
                        _guardar(items);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<({String seccion, String ubicacion})> _parsear() {
    final result = <({String seccion, String ubicacion})>[];
    for (final parte in distribucionActual.split(',')) {
      final p = parte.trim();
      if (p.isEmpty) continue;
      final sep = p.indexOf(':');
      if (sep == -1) {
        result.add((seccion: p, ubicacion: 'full'));
      } else {
        result.add((
          seccion: p.substring(0, sep),
          ubicacion: p.substring(sep + 1),
        ));
      }
    }
    for (final sec in idsSecciones) {
      if (!result.any((r) => r.seccion == sec)) {
        result.add((seccion: sec, ubicacion: 'full'));
      }
    }
    return result;
  }

  void _mover(List<({String seccion, String ubicacion})> items, int from, int to) {
    final item = items.removeAt(from);
    items.insert(to, item);
    _guardar(items);
  }

  void _guardar(List<({String seccion, String ubicacion})> items) {
    onCambiar(Configuracion.serializarDistribucion(items));
  }
}
