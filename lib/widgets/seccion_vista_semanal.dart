import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/cita.dart';
import 'dialogo_cita.dart';
import '../i18n/calendario_i18n.dart';

/// Vista de los próximos 7 días desde hoy, adaptada al ancho disponible.
class SeccionVistaSemanal extends StatelessWidget {
  const SeccionVistaSemanal({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;
    final ahora = DateTime.now();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colors.primaryContainer,
            child: Text('📅 ${estado.t('principal.proximos_7_dias')}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer)),
          ),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final anchoDia = (constraints.maxWidth - 16) / 7;
              return Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(7, (i) {
                    final dia = ahora.add(Duration(days: i));
                    return SizedBox(
                      width: anchoDia,
                      child: _buildDia(context, estado, colors, dia, i == 0),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDia(BuildContext context, AgendaEstado estado,
      ColorScheme colors, DateTime dia, bool esHoy) {
    final dias = CalendarioI18n.diasAbrev3(estado.idioma);
    final fechaStr =
        '${dia.year}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
    final citas = estado.citasDelDia(fechaStr);
    final tareas = estado.tareasDelDia(fechaStr);

    return GestureDetector(
      onLongPress: () async {
        final cita = await showDialog<Cita>(
          context: context,
          builder: (_) => DialogoCita(fechaInicial: fechaStr),
        );
        if (cita != null) estado.agregarCita(cita);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
              color: esHoy ? colors.primary : colors.outlineVariant,
              width: esHoy ? 2 : 1),
          borderRadius: BorderRadius.circular(6),
          color: esHoy ? colors.primaryContainer.withValues(alpha: 0.3) : null,
        ),
        child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: esHoy ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5), topRight: Radius.circular(5)),
            ),
            child: Center(
              child: Text(
                '${dias[dia.weekday - 1]} ${dia.day}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 11,
                  color: esHoy ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
          ),
          if (citas.isEmpty && tareas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('—', style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.2), fontSize: 11)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...citas.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('${c.hora} ${c.descripcion}',
                        style: TextStyle(fontSize: 10, color: colors.primary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                  ...tareas.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text('${t.completada ? "✕" : "●"} ${t.titulo}',
                        style: TextStyle(fontSize: 10,
                            decoration: t.completada ? TextDecoration.lineThrough : null),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}
