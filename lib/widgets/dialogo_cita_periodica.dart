import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modelos/cita.dart';
import '../estado/agenda_estado.dart';
import '../i18n/calendario_i18n.dart';

/// Diálogo para crear citas periódicas (semanales o mensuales).
/// Genera múltiples citas individuales de golpe.
class DialogoCitaPeriodica extends StatefulWidget {
  const DialogoCitaPeriodica({super.key});

  @override
  State<DialogoCitaPeriodica> createState() => _DialogoCitaPeriodicaState();
}

class _DialogoCitaPeriodicaState extends State<DialogoCitaPeriodica> {
  final _descCtrl = TextEditingController();
  bool _esSemanal = true;
  int _hora = 0;
  int _minutos = 0;
  bool _incluirHora = false;

  // Semanal: días seleccionados (1=Lun ... 7=Dom)
  final Set<int> _diasSemana = {};

  // Mensual: meses seleccionados (1-12) + día del mes
  final Set<int> _meses = {};
  int _diaMes = 1;

  // Período
  late DateTime _desde;
  late DateTime _hasta;

  @override
  void initState() {
    super.initState();
    _desde = DateTime.now();
    _hasta = DateTime(_desde.year + 1, _desde.month, _desde.day);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final nombresDias = CalendarioI18n.diasAbrev3(estado.idioma);
    final nombresMeses = CalendarioI18n.mesesAbrev(estado.idioma);

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
                Text('🔄 ${estado.t('dialogo_cp.titulo')}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                // Descripción
                TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: estado.t('dialogo_cita.descripcion_label'),
                    hintText: estado.t('dialogo_cp.descripcion_hint'),
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Tipo: semanal o mensual
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(estado.t('dialogo_cp.semanal')),
                        icon: const Icon(Icons.calendar_view_week)),
                    ButtonSegment(value: false, label: Text(estado.t('dialogo_cp.mensual')),
                        icon: const Icon(Icons.calendar_view_month)),
                  ],
                  selected: {_esSemanal},
                  onSelectionChanged: (s) =>
                      setState(() => _esSemanal = s.first),
                ),
                const SizedBox(height: 16),

                // Selector según tipo
                if (_esSemanal) _buildSelectorDias(estado, nombresDias),
                if (!_esSemanal) _buildSelectorMeses(estado, nombresMeses),
                const SizedBox(height: 16),

                // Hora opcional
                CheckboxListTile(
                  title: Text(estado.t('dialogo_cp.incluir_hora')),
                  value: _incluirHora,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => _incluirHora = v ?? false),
                ),
                if (_incluirHora)
                  OutlinedButton.icon(
                    onPressed: _seleccionarHora,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                        '${_hora.toString().padLeft(2, '0')}:${_minutos.toString().padLeft(2, '0')}'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44)),
                  ),
                const SizedBox(height: 16),

                // Período
                Text(estado.t('dialogo_cp.periodo'), style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _seleccionarFecha(true),
                        child: Text(estado.t('dialogo_cp.desde').replaceAll('{fecha}', _fmtFecha(_desde))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _seleccionarFecha(false),
                        child: Text(estado.t('dialogo_cp.hasta').replaceAll('{fecha}', _fmtFecha(_hasta))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  estado.t('dialogo_cp.se_generaran').replaceAll('{n}', '${_calcularCitas().length}'),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(estado.t('comun.cancelar'))),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _crear,
                      icon: const Icon(Icons.check),
                      label: Text(estado.t('dialogo_cp.crear_n_citas').replaceAll('{n}', '${_calcularCitas().length}')),
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

  Widget _buildSelectorDias(AgendaEstado estado, List<String> nombresDias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(estado.t('dialogo_cp.dias_semana_label'),
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(7, (i) {
            final dia = i + 1;
            return FilterChip(
              label: Text(nombresDias[i]),
              selected: _diasSemana.contains(dia),
              onSelected: (sel) => setState(() {
                sel ? _diasSemana.add(dia) : _diasSemana.remove(dia);
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSelectorMeses(AgendaEstado estado, List<String> nombresMeses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(estado.t('dialogo_cp.meses_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(12, (i) {
            final mes = i + 1;
            return FilterChip(
              label: Text(nombresMeses[i]),
              selected: _meses.contains(mes),
              onSelected: (sel) => setState(() {
                sel ? _meses.add(mes) : _meses.remove(mes);
              }),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(estado.t('dialogo_cp.dia_del_mes'), style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            SizedBox(
              width: 70,
              child: DropdownButtonFormField<int>(
                initialValue: _diaMes,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true),
                items: List.generate(31, (i) => DropdownMenuItem(
                    value: i + 1, child: Text('${i + 1}'))),
                onChanged: (v) => setState(() => _diaMes = v ?? 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _seleccionarHora() async {
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hora, minute: _minutos),
    );
    if (r != null) setState(() { _hora = r.hour; _minutos = r.minute; });
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final r = await showDatePicker(
      context: context,
      initialDate: esDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (r != null) setState(() { esDesde ? _desde = r : _hasta = r; });
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<Cita> _calcularCitas() {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return [];

    final horaStr = _incluirHora
        ? '${_hora.toString().padLeft(2, '0')}:${_minutos.toString().padLeft(2, '0')}'
        : '00:00';

    final citas = <Cita>[];
    var dia = _desde;

    while (!dia.isAfter(_hasta)) {
      bool crear = false;

      if (_esSemanal) {
        crear = _diasSemana.contains(dia.weekday);
      } else {
        crear = _meses.contains(dia.month) && dia.day == _diaMes;
      }

      if (crear) {
        final fechaStr =
            '${dia.year}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
        citas.add(Cita(fecha: fechaStr, hora: horaStr, descripcion: desc));
      }

      dia = dia.add(const Duration(days: 1));
    }
    return citas;
  }

  void _crear() {
    final citas = _calcularCitas();
    if (citas.isEmpty) return;
    Navigator.pop(context, citas);
  }
}
