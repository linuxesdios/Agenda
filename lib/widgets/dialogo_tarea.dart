import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modelos/tarea.dart';
import '../estado/agenda_estado.dart';

/// Diálogo para crear o editar una tarea.
/// CREAR: solo pide nombre + destino (simple y rápido).
/// EDITAR: muestra todos los campos (fecha, etiqueta, persona, estado).
class DialogoTarea extends StatefulWidget {
  final Tarea? tareaExistente;
  final String? destinoInicial;

  const DialogoTarea({super.key, this.tareaExistente, this.destinoInicial});

  @override
  State<DialogoTarea> createState() => _DialogoTareaState();
}

class _DialogoTareaState extends State<DialogoTarea> {
  late final TextEditingController _tituloCtrl;
  late String _destino;
  String? _fecha;
  String? _hora;
  bool _incluirHora = false;
  String? _etiquetaSeleccionada;
  String? _personaSeleccionada;
  String _estado = 'pendiente';

  @override
  void initState() {
    super.initState();
    final t = widget.tareaExistente;
    _tituloCtrl = TextEditingController(text: t?.titulo ?? '');
    _destino = widget.destinoInicial ?? 'criticas';
    _fecha = t?.soloFecha;
    _hora = t?.soloHora;
    _incluirHora = _hora != null;
    _etiquetaSeleccionada = t?.etiqueta;
    _personaSeleccionada = t?.persona;
    _estado = t?.estado ?? 'pendiente';
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  bool get _esEdicion => widget.tareaExistente != null;

  @override
  Widget build(BuildContext context) {
    final estado = context.read<AgendaEstado>();
    final listas = estado.listasPersonalizadas;

    // CREAR → diálogo simple: solo nombre + destino
    if (!_esEdicion) {
      return AlertDialog(
        title: Text('➕ ${estado.t('dialogo_tarea.nueva_titulo')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloCtrl,
              decoration: InputDecoration(
                hintText: estado.t('dialogo_tarea.que_hacer_hint'),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _guardar(),
            ),
            if (widget.destinoInicial == null) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _destino,
                decoration: InputDecoration(
                  labelText: estado.t('dialogo_tarea.donde_label'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                      value: 'criticas', child: Text('🚨 ${estado.t('dialogo_tarea.criticas_opcion')}')),
                  ...listas.map((l) => DropdownMenuItem(
                      value: l.id, child: Text('${l.emoji} ${l.nombre}'))),
                ],
                onChanged: (v) => setState(() => _destino = v ?? 'criticas'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(estado.t('comun.cancelar'))),
          FilledButton(
              onPressed: _guardar, child: Text(estado.t('comun.crear'))),
        ],
      );
    }

    // EDITAR → diálogo completo con todos los campos
    final etiquetas = estado.etiquetasTareas;
    final personas = estado.personas;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, minWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✏️ ${estado.t('dialogo_tarea.editar_titulo')}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                TextField(
                  controller: _tituloCtrl,
                  decoration: InputDecoration(
                    labelText: estado.t('dialogo_tarea.titulo_label'),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),

                // Fecha
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarFecha,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_fecha ?? estado.t('dialogo_tarea.sin_fecha')),
                        style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size(0, 44)),
                      ),
                    ),
                    if (_fecha != null)
                      IconButton(icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _fecha = null; _hora = null; _incluirHora = false;
                          })),
                  ],
                ),
                if (_fecha != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(value: _incluirHora, onChanged: (v) =>
                          setState(() { _incluirHora = v ?? false; if (!_incluirHora) _hora = null; })),
                      Text(estado.t('dialogo_tarea.hora_label')),
                      if (_incluirHora)
                        TextButton(
                          onPressed: _seleccionarHora,
                          child: Text(_hora ?? estado.t('dialogo_tarea.elegir')),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Etiqueta
                DropdownButtonFormField<String>(
                  initialValue: etiquetas.any((e) => e.nombre == _etiquetaSeleccionada)
                      ? _etiquetaSeleccionada : null,
                  decoration: InputDecoration(
                    labelText: '🏷️ ${estado.t('dialogo_tarea.etiqueta_label')}', border: const OutlineInputBorder(), isDense: true),
                  items: [
                    DropdownMenuItem(value: null, child: Text(estado.t('dialogo_cita.sin_etiqueta'))),
                    ...etiquetas.map((e) => DropdownMenuItem(
                        value: e.nombre, child: Text('${e.emoji} ${e.nombre}'))),
                  ],
                  onChanged: (v) => setState(() => _etiquetaSeleccionada = v),
                ),
                const SizedBox(height: 12),

                // Persona
                DropdownButtonFormField<String>(
                  initialValue: personas.contains(_personaSeleccionada)
                      ? _personaSeleccionada : null,
                  decoration: InputDecoration(
                    labelText: '👤 ${estado.t('dialogo_tarea.persona_label')}', border: const OutlineInputBorder(), isDense: true),
                  items: [
                    DropdownMenuItem(value: null, child: Text(estado.t('dialogo_tarea.no_asignar'))),
                    ...personas.map((p) => DropdownMenuItem(value: p, child: Text('👤 $p'))),
                  ],
                  onChanged: (v) => setState(() => _personaSeleccionada = v),
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context),
                        child: Text(estado.t('comun.cancelar'))),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _guardar, child: Text(estado.t('comun.guardar'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final r = await showDatePicker(
      context: context,
      initialDate: _fecha != null ? (DateTime.tryParse(_fecha!) ?? ahora) : ahora,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (r != null) {
      setState(() => _fecha =
          '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _seleccionarHora() async {
    final r = await showTimePicker(
      context: context,
      initialTime: _hora != null
          ? TimeOfDay(hour: int.parse(_hora!.split(':')[0]),
              minute: int.parse(_hora!.split(':')[1]))
          : TimeOfDay.now(),
    );
    if (r != null) {
      setState(() => _hora =
          '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}');
    }
  }

  void _guardar() {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) return;
    String? fechaLimite;
    if (_fecha != null) {
      fechaLimite = _incluirHora && _hora != null ? '${_fecha}T$_hora' : _fecha;
    }
    final tarea = Tarea(
      id: widget.tareaExistente?.id,
      titulo: titulo,
      fechaLimite: fechaLimite,
      etiqueta: _etiquetaSeleccionada,
      estado: _estado,
      persona: _personaSeleccionada,
      subtareas: widget.tareaExistente?.subtareas ?? [],
      fechaCreacion: widget.tareaExistente?.fechaCreacion,
      fechaCompletada: widget.tareaExistente?.fechaCompletada,
    );
    Navigator.pop(context, {'tarea': tarea, 'destino': _destino});
  }
}

/// Diálogo simple para agregar una subtarea.
Future<Subtarea?> mostrarDialogoSubtarea(BuildContext context,
    {List<String>? personas}) async {
  final textoCtrl = TextEditingController();
  final estado = context.read<AgendaEstado>();
  return showDialog<Subtarea>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('📝 ${estado.t('dialogo_tarea.subtarea_titulo')}'),
      content: TextField(
        controller: textoCtrl,
        decoration: InputDecoration(
          hintText: estado.t('dialogo_tarea.subtarea_hint'),
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(ctx, Subtarea(texto: v.trim()));
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(estado.t('comun.cancelar'))),
        FilledButton(onPressed: () {
          final t = textoCtrl.text.trim();
          if (t.isNotEmpty) Navigator.pop(ctx, Subtarea(texto: t));
        }, child: Text(estado.t('comun.anadir'))),
      ],
    ),
  );
}
