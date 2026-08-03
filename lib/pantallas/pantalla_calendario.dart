import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/cita.dart';
import '../widgets/dialogo_cita.dart';
import '../i18n/calendario_i18n.dart';

class PantallaCalendario extends StatefulWidget {
  const PantallaCalendario({super.key});

  @override
  State<PantallaCalendario> createState() => _PantallaCalendarioState();
}

class _PantallaCalendarioState extends State<PantallaCalendario> {
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
    final diasSemana = CalendarioI18n.diasAbrev3(estado.idioma);
    final nombresMeses = CalendarioI18n.mesesAbrev(estado.idioma);

    return Scaffold(
      appBar: AppBar(
        title: Text('📅 ${estado.t('calendario.titulo')}'),
        backgroundColor: colors.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ═══ HEADER MES ═══
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() =>
                    _mesActual = DateTime(_mesActual.year, _mesActual.month - 1)),
              ),
              Text(
                '${nombresMeses[_mesActual.month - 1]} ${_mesActual.year}',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() =>
                    _mesActual = DateTime(_mesActual.year, _mesActual.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ═══ DÍAS DE LA SEMANA ═══
          Row(
            children: diasSemana
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.primary)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // ═══ GRID DE DÍAS (compacto) ═══
          _buildGrid(colors, diasConEventos),
          const Divider(height: 24),

          // ═══ DETALLE DEL DÍA SELECCIONADO ═══
          _buildDetalleDia(context, estado, colors),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _crearCita(context, estado),
        child: const Icon(Icons.add),
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
          celdas.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final dia = diaActual;
          final fechaStr =
              _fmt(DateTime(_mesActual.year, _mesActual.month, dia));
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
                height: 40,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: sel
                      ? colors.primary
                      : esHoy
                          ? colors.primaryContainer
                          : null,
                  borderRadius: BorderRadius.circular(6),
                  border: esHoy && !sel
                      ? Border.all(color: colors.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: esHoy || sel ? FontWeight.bold : null,
                        color: sel ? colors.onPrimary : null,
                      ),
                    ),
                    if (tieneEventos)
                      Container(
                        width: 5, height: 5,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? colors.onPrimary : colors.error,
                        ),
                      ),
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

  Widget _buildDetalleDia(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    final citas = estado.citasDelDia(_diaSeleccionado);
    final tareas = estado.tareasDelDia(_diaSeleccionado);
    final partes = _diaSeleccionado.split('-');
    final fechaLegible = '${partes[2]}/${partes[1]}/${partes[0]}';
    final esHoy = _diaSeleccionado == _fmt(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '📅 $fechaLegible',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
            ),
            if (esHoy) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(estado.t('calendario.hoy_chip')),
                backgroundColor: colors.primaryContainer,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // ── CITAS ──
        if (citas.isNotEmpty) ...[
          Text('🕐 ${estado.t('calendario.citas')} (${citas.length})',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          ...citas.map((cita) {
            final idx = estado.citas.indexOf(cita);
            final etiqueta = estado.buscarEtiqueta(cita.etiqueta);
            return Card(
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primaryContainer,
                  child: Text(cita.hora.substring(0, 2),
                      style: TextStyle(fontSize: 12, color: colors.primary)),
                ),
                title: Text(cita.descripcion),
                subtitle: Row(children: [
                  Text('🕐 ${cita.hora}'),
                  if (etiqueta != null) ...[
                    const SizedBox(width: 6),
                    Text('${etiqueta.emoji} ${etiqueta.nombre}',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ]),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'editar', child: Text('✏️ ${estado.t('comun.editar')}')),
                    PopupMenuItem(value: 'eliminar', child: Text('🗑️ ${estado.t('comun.eliminar')}')),
                  ],
                  onSelected: (v) async {
                    if (v == 'editar') {
                      final editada = await showDialog<Cita>(
                          context: context,
                          builder: (_) => DialogoCita(citaExistente: cita));
                      if (editada != null && idx >= 0) {
                        await estado.editarCita(idx, editada);
                      }
                    } else if (v == 'eliminar' && idx >= 0) {
                      await estado.eliminarCita(idx);
                    }
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // ── TAREAS ──
        if (tareas.isNotEmpty) ...[
          Text('✅ ${estado.t('calendario.tareas')} (${tareas.length})',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          ...tareas.map((t) {
            final urgente = !t.completada && (t.esHoy || t.esPasada);
            return Card(
              color: urgente ? colors.errorContainer.withValues(alpha: 0.3) : null,
              child: ListTile(
                dense: true,
                leading: Icon(
                  t.completada ? Icons.check_circle : Icons.circle_outlined,
                  color: t.completada
                      ? Colors.green
                      : urgente
                          ? colors.error
                          : Colors.grey,
                  size: 20,
                ),
                title: Text(
                  t.titulo,
                  style: TextStyle(
                    decoration: t.completada ? TextDecoration.lineThrough : null,
                    fontWeight: urgente ? FontWeight.bold : null,
                    color: urgente ? colors.error : null,
                  ),
                ),
                subtitle: Row(children: [
                  if (t.soloHora != null) Text('🕐 ${t.soloHora}  '),
                  if (urgente)
                    Text(t.esPasada ? '⚠️ ${estado.t('calendario.vencida')}' : '⚠️ ${estado.t('calendario.hoy_mayus')}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.error)),
                  if (t.persona != null && t.persona!.isNotEmpty)
                    Text('  👤 ${t.persona}',
                        style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        if (citas.isEmpty && tareas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(estado.t('calendario.sin_eventos_dia'),
                  style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.5))),
            ),
          ),

        // Botón añadir
        Center(
          child: TextButton.icon(
            onPressed: () => _crearCita(context, estado),
            icon: const Icon(Icons.add, size: 18),
            label: Text(estado.t('calendario.anadir_cita_dia')),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _crearCita(BuildContext context, AgendaEstado estado) async {
    final cita = await showDialog<Cita>(
      context: context,
      builder: (_) => DialogoCita(fechaInicial: _diaSeleccionado),
    );
    if (cita != null) await estado.agregarCita(cita);
  }
}
