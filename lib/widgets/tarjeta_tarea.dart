import 'package:flutter/material.dart';
import '../modelos/tarea.dart';
import '../modelos/etiqueta.dart';
import '../estado/agenda_estado.dart';
import 'package:provider/provider.dart';
import '../i18n/idioma.dart';
import '../i18n/traducciones.dart';

// ═══════════════════════════════════════════
// BULLET JOURNAL — símbolos y colores
// ═══════════════════════════════════════════

String simboloBujo(String estado) {
  switch (estado) {
    case 'completada':  return '✕';
    case 'migrada':     return '>';
    case 'programada':  return '<';
    case 'importante':  return '*';
    case 'idea':        return '!';
    case 'investigar':  return '?';
    default:            return '●';
  }
}

Color colorBujo(String estado, ColorScheme colors) {
  switch (estado) {
    case 'completada':  return Colors.green;
    case 'migrada':     return Colors.purple;
    case 'programada':  return Colors.blue;
    case 'importante':  return Colors.red;
    case 'idea':        return Colors.amber.shade700;
    case 'investigar':  return Colors.teal;
    default:            return colors.onSurface;
  }
}

String nombreEstado(String estado, Idioma idioma) {
  switch (estado) {
    case 'completada':  return Traducciones.t(idioma, 'estado.completada');
    case 'migrada':     return Traducciones.t(idioma, 'estado.migrada');
    case 'programada':  return Traducciones.t(idioma, 'estado.programada');
    case 'importante':  return Traducciones.t(idioma, 'estado.importante');
    case 'idea':        return Traducciones.t(idioma, 'estado.idea');
    case 'investigar':  return Traducciones.t(idioma, 'estado.investigar');
    default:            return Traducciones.t(idioma, 'estado.pendiente');
  }
}

String siguienteEstado(String actual) {
  const ciclo = ['pendiente', 'completada'];
  final idx = ciclo.indexOf(actual);
  if (idx == -1) return 'pendiente';
  return ciclo[(idx + 1) % ciclo.length];
}

// ═══════════════════════════════════════════
// TARJETA DE TAREA
// ═══════════════════════════════════════════

class TarjetaTarea extends StatelessWidget {
  final Tarea tarea;
  final int index;
  final VoidCallback onCambiarEstado;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onAgregarSubtarea;
  final String? listaId;
  final Function(int subIndex)? onCambiarEstadoSubtarea;
  final Function(int subIndex)? onEliminarSubtarea;
  final Function()? onHacerCritica;
  final Function(String estado, {String? persona, String? fecha})?
      onCambiarEstadoConDatos;

  const TarjetaTarea({
    super.key,
    required this.tarea,
    required this.index,
    required this.onCambiarEstado,
    required this.onEditar,
    required this.onEliminar,
    required this.onAgregarSubtarea,
    this.listaId,
    this.onCambiarEstadoSubtarea,
    this.onEliminarSubtarea,
    this.onHacerCritica,
    this.onCambiarEstadoConDatos,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final agendaEstado = context.read<AgendaEstado>();
    final etiquetaInfo = agendaEstado.buscarEtiqueta(tarea.etiqueta);
    final esUrgente = !tarea.completada && (tarea.esHoy || tarea.esPasada);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: esUrgente
            ? colors.errorContainer.withValues(alpha: 0.25)
            : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: esUrgente
            ? Border.all(color: colors.error, width: 2)
            : Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // ── SÍMBOLO BUJO: tap = menú BuJo ──
                GestureDetector(
                  onTap: () => _mostrarMenuBujo(context, agendaEstado, colors),
                  child: Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colorBujo(tarea.estado, colors), width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      simboloBujo(tarea.estado),
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: colorBujo(tarea.estado, colors),
                      ),
                    ),
                  ),
                ),

                // ── TÍTULO: tap = menú BuJo, doble tap = editar ──
                Expanded(
                  child: GestureDetector(
                    onTap: () => _mostrarMenuBujo(context, agendaEstado, colors),
                    onDoubleTap: onEditar,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tarea.titulo,
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            decoration: tarea.completada
                                ? TextDecoration.lineThrough : null,
                            color: tarea.completada
                                ? colors.onSurface.withValues(alpha: 0.4)
                                : esUrgente ? colors.error : colors.onSurface,
                          ),
                        ),
                        _buildBadgesRow(etiquetaInfo, colors, esUrgente, agendaEstado.idioma),
                      ],
                    ),
                  ),
                ),

                  // ── ✓ completar ──
                  GestureDetector(
                    onTap: onCambiarEstado,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.check, size: 20,
                          color: tarea.completada
                              ? Colors.green
                              : colors.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),

                  // ── ✕ borrar ──
                  GestureDetector(
                    onTap: onEliminar,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 20,
                          color: colors.error.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),

            // ── SUBTAREAS ──
            if (tarea.subtareas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 44, right: 8, bottom: 4),
                child: Column(
                  children: List.generate(tarea.subtareas.length, (si) =>
                      _buildSubtarea(tarea.subtareas[si], si, colors)),
                ),
              ),
          ],
        ),
    );
  }

  // ═══════════════════════════════════════════
  // MENÚ BULLET JOURNAL
  // ═══════════════════════════════════════════

  void _mostrarMenuBujo(
      BuildContext context, AgendaEstado estado, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tarea.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            _opcion(ctx, '●', estado.t('estado.pendiente'), 'pendiente', colors),
            _opcion(ctx, '>', estado.t('tarea.opcion_migrada'), 'migrada', colors,
                accion: () => _pedirPersona(ctx, estado)),
            _opcion(ctx, '<', estado.t('tarea.opcion_programada'), 'programada', colors,
                accion: () => _pedirFecha(ctx)),
            _opcion(ctx, '*', estado.t('tarea.opcion_importante'), 'importante', colors),
            _opcion(ctx, '!', estado.t('tarea.opcion_idea'), 'idea', colors),
            _opcion(ctx, '?', estado.t('tarea.opcion_investigar'), 'investigar', colors),
            if (listaId != null && onHacerCritica != null)
              ListTile(
                leading: _simboloBox('🚨', Colors.red),
                title: Text(estado.t('tarea.mover_criticas')),
                onTap: () { Navigator.pop(ctx); onHacerCritica!(); },
              ),
            ListTile(
              leading: _simboloBox('+', colors.primary),
              title: Text(estado.t('tarea.anadir_subtarea')),
              onTap: () { Navigator.pop(ctx); onAgregarSubtarea(); },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_note, size: 20, color: colors.primary),
              title: Text(estado.t('tarea.editar_todos_campos')),
              onTap: () { Navigator.pop(ctx); onEditar(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _simboloBox(String s, Color color) {
    return Container(
      width: 28, height: 28, alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(s, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _opcion(BuildContext ctx, String simbolo, String texto,
      String nuevoEstado, ColorScheme colors, {VoidCallback? accion}) {
    final sel = tarea.estado == nuevoEstado;
    return ListTile(
      leading: Container(
        width: 28, height: 28, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? colorBujo(nuevoEstado, colors).withValues(alpha: 0.15) : null,
          border: Border.all(color: colorBujo(nuevoEstado, colors), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(simbolo, style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.bold, color: colorBujo(nuevoEstado, colors))),
      ),
      title: Text(texto, style: TextStyle(fontWeight: sel ? FontWeight.bold : null)),
      trailing: sel ? Icon(Icons.check, color: colorBujo(nuevoEstado, colors)) : null,
      onTap: () {
        Navigator.pop(ctx);
        if (accion != null) { accion(); } else {
          // Al volver a pendiente, limpiar fecha y persona
          if (nuevoEstado == 'pendiente') {
            onCambiarEstadoConDatos?.call('pendiente', persona: '', fecha: '') ??
                onCambiarEstado();
          } else {
            onCambiarEstadoConDatos?.call(nuevoEstado) ?? onCambiarEstado();
          }
        }
      },
    );
  }

  Future<void> _pedirPersona(BuildContext ctx, AgendaEstado estado) async {
    final personas = estado.personas;
    String? persona;
    if (personas.isNotEmpty) {
      persona = await showDialog<String>(
        context: ctx,
        builder: (dCtx) => SimpleDialog(
          title: Text('> ${estado.t('tarea.migrar_a')}'),
          children: [
            ...personas.map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dCtx, p),
                  child: Text('👤 $p'),
                )),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dCtx, '__nueva__'),
              child: Text('➕ ${estado.t('tarea.otra_persona')}'),
            ),
          ],
        ),
      );
    } else {
      persona = '__nueva__';
    }
    if (persona == '__nueva__' && ctx.mounted) {
      final ctrl = TextEditingController();
      persona = await showDialog<String>(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          title: Text(estado.t('principal.nombre_label')),
          content: TextField(controller: ctrl, autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (v) => Navigator.pop(dCtx, v.trim())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(estado.t('comun.cancelar'))),
            FilledButton(onPressed: () => Navigator.pop(dCtx, ctrl.text.trim()), child: const Text('OK')),
          ],
        ),
      );
    }
    if (persona != null && persona.isNotEmpty) {
      onCambiarEstadoConDatos?.call('migrada', persona: persona);
    }
  }

  Future<void> _pedirFecha(BuildContext ctx) async {
    final fecha = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      final f = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      onCambiarEstadoConDatos?.call('programada', fecha: f);
    }
  }

  // ═══════════════════════════════════════════
  // BADGES Y SUBTAREAS
  // ═══════════════════════════════════════════

  Widget _buildBadgesRow(Etiqueta? etiquetaInfo, ColorScheme colors, bool esUrgente, Idioma idioma) {
    final badges = <Widget>[];
    if (!['pendiente', 'completada'].contains(tarea.estado)) {
      badges.add(_badge('${simboloBujo(tarea.estado)} ${nombreEstado(tarea.estado, idioma)}',
          colorBujo(tarea.estado, colors)));
    }
    if (esUrgente) {
      badges.add(_badge(tarea.esPasada
          ? '⚠️ ${Traducciones.t(idioma, 'tarea.vencida')}'
          : '⚠️ ${Traducciones.t(idioma, 'tarea.hoy')}', colors.error));
    } else if (tarea.fechaLimite != null) {
      badges.add(_badge('📅 ${tarea.fechaFormateada}', colors.onSurface));
    }
    if (tarea.persona != null && tarea.persona!.isNotEmpty) {
      badges.add(_badge('👤 ${tarea.persona}', Colors.blue));
    }
    if (etiquetaInfo != null) {
      badges.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: _parseColor(etiquetaInfo.color).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('${etiquetaInfo.emoji} ${etiquetaInfo.nombre}',
            style: const TextStyle(fontSize: 10)),
      ));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(spacing: 4, runSpacing: 2, children: badges),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSubtarea(Subtarea sub, int si, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onCambiarEstadoSubtarea?.call(si),
            child: Container(
              width: 18, height: 18, alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                border: Border.all(color: colorBujo(sub.estado, colors), width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(simboloBujo(sub.estado), style: TextStyle(fontSize: 9,
                  fontWeight: FontWeight.bold, color: colorBujo(sub.estado, colors))),
            ),
          ),
          Expanded(child: Text(sub.texto, style: TextStyle(fontSize: 13,
              decoration: sub.estado == 'completada' ? TextDecoration.lineThrough : null,
              color: sub.estado == 'completada' ? colors.onSurface.withValues(alpha: 0.4) : null))),
          if (sub.persona != null && sub.persona!.isNotEmpty)
            Text('👤 ${sub.persona}', style: const TextStyle(fontSize: 10, color: Colors.blue)),
          GestureDetector(
            onTap: () => onEliminarSubtarea?.call(si),
            child: Padding(padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 14, color: colors.error)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
