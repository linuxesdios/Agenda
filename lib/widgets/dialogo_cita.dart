import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modelos/cita.dart';
import '../estado/agenda_estado.dart';

/// Diálogo para crear o editar una cita, con selector de recordatorios múltiples.
class DialogoCita extends StatefulWidget {
  final Cita? citaExistente;
  final String? fechaInicial;

  const DialogoCita({super.key, this.citaExistente, this.fechaInicial});

  @override
  State<DialogoCita> createState() => _DialogoCitaState();
}

class _DialogoCitaState extends State<DialogoCita> {
  late final TextEditingController _descCtrl;
  late String _fecha;
  late int _hora;
  late int _minutos;
  String? _etiquetaSeleccionada;
  late Set<int> _recordatorios;

  @override
  void initState() {
    super.initState();
    final c = widget.citaExistente;
    _descCtrl = TextEditingController(text: c?.descripcion ?? '');

    if (c != null) {
      _fecha = c.fecha;
      final hm = c.hora.split(':');
      _hora = int.parse(hm[0]);
      _minutos = int.parse(hm[1]);
      _etiquetaSeleccionada = c.etiqueta;
      _recordatorios = Set.from(c.recordatorios);
    } else {
      _fecha = widget.fechaInicial ?? _hoyStr();
      _hora = 14;
      _minutos = 0;
      // Usar recordatorios por defecto de la configuración (se leen en build)
      _recordatorios = {15};
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aplicar recordatorios por defecto al crear (solo primera vez)
    if (widget.citaExistente == null) {
      final cfg = context.read<AgendaEstado>().configuracion;
      _recordatorios = Set.from(cfg.recordatoriosPorDefecto);
    }
  }

  String _hoyStr() {
    final h = DateTime.now();
    return '${h.year}-${h.month.toString().padLeft(2, '0')}-${h.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.read<AgendaEstado>();
    final etiquetas = estado.etiquetasCitas;
    final esEdicion = widget.citaExistente != null;

    final opcionesRecordatorio = [
      (minutos: 15, label: estado.t('dialogo_cita.recordatorio_15')),
      (minutos: 60, label: estado.t('dialogo_cita.recordatorio_60')),
      (minutos: 1440, label: estado.t('dialogo_cita.recordatorio_1440')),
    ];

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
                Text(esEdicion
                        ? '✏️ ${estado.t('dialogo_cita.editar_titulo')}'
                        : '📅 ${estado.t('dialogo_cita.nueva_titulo')}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                // Fecha
                OutlinedButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('📅  ${_fechaLegible()}'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      alignment: Alignment.centerLeft),
                ),
                const SizedBox(height: 12),

                // Descripción
                TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: estado.t('dialogo_cita.descripcion_label'),
                    hintText: estado.t('dialogo_cita.descripcion_hint'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                  autofocus: !esEdicion,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),

                // Hora
                OutlinedButton.icon(
                  onPressed: _seleccionarHora,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(
                      '🕐  ${_hora.toString().padLeft(2, '0')}:${_minutos.toString().padLeft(2, '0')}'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      alignment: Alignment.centerLeft),
                ),
                const SizedBox(height: 12),

                // Recordatorios
                Text('🔔 ${estado.t('dialogo_cita.recordatorios')}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...opcionesRecordatorio.map((op) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(op.label),
                      value: _recordatorios.contains(op.minutos),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _recordatorios.add(op.minutos);
                        } else {
                          _recordatorios.remove(op.minutos);
                        }
                      }),
                    )),
                const SizedBox(height: 12),

                // Etiqueta
                if (etiquetas.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: etiquetas.any(
                            (e) => e.nombre == _etiquetaSeleccionada)
                        ? _etiquetaSeleccionada
                        : null,
                    decoration: InputDecoration(
                      labelText: '🏷️ ${estado.t('dialogo_cita.etiqueta_opcional')}',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(estado.t('dialogo_cita.sin_etiqueta'))),
                      ...etiquetas.map((e) => DropdownMenuItem(
                            value: e.nombre,
                            child: Text('${e.emoji} ${e.nombre}'),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _etiquetaSeleccionada = v),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(estado.t('comun.cancelar')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.check),
                      label: Text(esEdicion
                          ? estado.t('comun.guardar')
                          : estado.t('dialogo_cita.anadir_cita_boton')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fechaLegible() {
    final p = _fecha.split('-');
    if (p.length != 3) return _fecha;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  Future<void> _seleccionarFecha() async {
    final r = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (r != null && mounted) {
      setState(() => _fecha =
          '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _seleccionarHora() async {
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hora, minute: _minutos),
    );
    if (r != null && mounted) {
      setState(() {
        _hora = r.hour;
        _minutos = r.minute;
      });
    }
  }

  void _guardar() {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    final horaStr =
        '${_hora.toString().padLeft(2, '0')}:${_minutos.toString().padLeft(2, '0')}';
    Navigator.pop(
      context,
      Cita(
        id: widget.citaExistente?.id,
        fecha: _fecha,
        hora: horaStr,
        descripcion: desc,
        etiqueta: _etiquetaSeleccionada,
        recordatorios: _recordatorios.toList()..sort(),
      ),
    );
  }
}
