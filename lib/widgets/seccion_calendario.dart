import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/cita.dart';
import 'dialogo_cita.dart';
import '../i18n/calendario_i18n.dart';

/// Calendario inline como sección de la pantalla principal.
/// Muestra el grid mensual + detalle del día seleccionado.
class SeccionCalendario extends StatefulWidget {
  const SeccionCalendario({super.key});

  @override
  State<SeccionCalendario> createState() => _SeccionCalendarioState();
}

class _SeccionCalendarioState extends State<SeccionCalendario> {
  late DateTime _mesActual;
  late String _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _mesActual = DateTime(ahora.year, ahora.month);
    _diaSeleccionado = _fmt(ahora);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;
    final diasConEventos =
        estado.diasConEventos(_mesActual.year, _mesActual.month);
    final diasSemana = CalendarioI18n.diasAbrev1(estado.idioma);
    final nombresMeses = CalendarioI18n.mesesAbrev(estado.idioma);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: colors.primaryContainer,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() =>
                      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${nombresMeses[_mesActual.month - 1]} ${_mesActual.year}',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() =>
                      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1)),
                ),
              ],
            ),
          ),

          // Días de la semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: diasSemana
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary)),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Grid de días
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildGrid(colors, diasConEventos),
          ),

          // Detalle del día
          _buildDetalle(context, estado, colors),
        ],
      ),
    );
  }

  Widget _buildGrid(ColorScheme colors, Set<int> diasConEventos) {
    final primerDia = DateTime(_mesActual.year, _mesActual.month, 1);
    final ultimoDia = DateTime(_mesActual.year, _mesActual.month + 1, 0);
    final offsetInicio = primerDia.weekday - 1;
    final totalDias = ultimoDia.day;
    final hoyStr = _fmt(DateTime.now());

    final filas = <Widget>[];
    var diaActual = 1 - offsetInicio;

    while (diaActual <= totalDias) {
      final celdas = <Widget>[];
      for (var col = 0; col < 7; col++) {
        if (diaActual < 1 || diaActual > totalDias) {
          celdas.add(const Expanded(child: SizedBox(height: 32)));
        } else {
          final dia = diaActual;
          final fechaStr = _fmt(DateTime(_mesActual.year, _mesActual.month, dia));
          final esHoy = fechaStr == hoyStr;
          final sel = fechaStr == _diaSeleccionado;
          final tieneEventos = diasConEventos.contains(dia);

          celdas.add(Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _diaSeleccionado = fechaStr),
              onLongPress: () async {
                final estado = context.read<AgendaEstado>();
                final cita = await showDialog<Cita>(
                  context: context,
                  builder: (_) => DialogoCita(fechaInicial: fechaStr),
                );
                if (cita != null) estado.agregarCita(cita);
              },
              child: Container(
                height: 32,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: sel ? colors.primary
                      : esHoy ? colors.primaryContainer : null,
                  borderRadius: BorderRadius.circular(4),
                  border: esHoy && !sel
                      ? Border.all(color: colors.primary, width: 1.5) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dia', style: TextStyle(
                      fontSize: 12,
                      fontWeight: esHoy || sel ? FontWeight.bold : null,
                      color: sel ? colors.onPrimary : null,
                    )),
                    if (tieneEventos)
                      Container(width: 4, height: 4,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: sel ? colors.onPrimary : colors.error)),
                  ],
                ),
              ),
            ),
          ));
        }
        diaActual++;
      }
      filas.add(Row(children: celdas));
    }
    return Column(children: filas);
  }

  Widget _buildDetalle(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    final citas = estado.citasDelDia(_diaSeleccionado);
    final tareas = estado.tareasDelDia(_diaSeleccionado);
    final partes = _diaSeleccionado.split('-');
    final fechaLegible = '${partes[2]}/${partes[1]}';
    final esHoy = _diaSeleccionado == _fmt(DateTime.now());

    if (citas.isEmpty && tareas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text('$fechaLegible — ${estado.t('calendario.sin_eventos_corto')}',
              style: TextStyle(fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.5))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(fechaLegible, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.bold, color: colors.primary)),
            if (esHoy) ...[
              const SizedBox(width: 6),
              Text(estado.t('calendario.hoy_mayus'), style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.bold, color: colors.primary)),
            ],
          ]),
          ...citas.map((c) {
            final et = estado.buscarEtiqueta(c.etiqueta);
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                Text('🕐 ${c.hora} ', style: const TextStyle(fontSize: 11)),
                Expanded(child: Text(c.descripcion,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
                if (et != null) Text(' ${et.emoji}', style: const TextStyle(fontSize: 11)),
              ]),
            );
          }),
          ...tareas.map((t) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(children: [
              Text('${t.completada ? "✕" : "●"} ',
                  style: TextStyle(fontSize: 11,
                      color: t.completada ? Colors.green : colors.onSurface)),
              Expanded(child: Text(t.titulo,
                  style: TextStyle(fontSize: 12,
                      decoration: t.completada ? TextDecoration.lineThrough : null),
                  overflow: TextOverflow.ellipsis)),
            ]),
          )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
