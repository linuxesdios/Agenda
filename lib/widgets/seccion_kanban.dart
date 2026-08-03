import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/tarea.dart';
import 'tarjeta_tarea.dart';

/// Vista Kanban — tablero horizontal con columnas por estado BuJo.
/// Puede usarse como popup fullscreen (esPopup=true) o inline.
class SeccionKanban extends StatelessWidget {
  final bool esPopup;
  final VoidCallback? onCerrar;

  const SeccionKanban({super.key, this.esPopup = false, this.onCerrar});

  static List<({String estado, String titulo, Color color})> _columnas(
      AgendaEstado estado) => [
    (estado: 'pendiente', titulo: '● ${estado.t('estado.pendiente')}', color: Colors.grey),
    (estado: 'importante', titulo: '* ${estado.t('estado.importante')}', color: Colors.red),
    (estado: 'programada', titulo: '< ${estado.t('estado.programada')}', color: Colors.blue),
    (estado: 'migrada', titulo: '> ${estado.t('estado.migrada')}', color: Colors.purple),
    (estado: 'idea', titulo: '! ${estado.t('estado.idea')}', color: Colors.amber),
    (estado: 'investigar', titulo: '? ${estado.t('estado.investigar')}', color: Colors.teal),
    (estado: 'completada', titulo: '✕ ${estado.t('estado.completada')}', color: Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;

    // Recopilar TODAS las tareas (críticas + todas las listas)
    final todasTareas = <_TareaKanban>[];
    for (var i = 0; i < estado.tareasCriticas.length; i++) {
      todasTareas.add(_TareaKanban(estado.tareasCriticas[i], 'criticas', i));
    }
    for (final lista in estado.listasPersonalizadas) {
      for (var i = 0; i < lista.tareas.length; i++) {
        todasTareas.add(_TareaKanban(lista.tareas[i], lista.id, i,
            nombreLista: '${lista.emoji} ${lista.nombre}'));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('📊 ${estado.t('kanban.titulo')}'),
        backgroundColor: colors.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onCerrar ?? () => Navigator.pop(context),
        ),
      ),
      body: _buildTablero(context, estado, colors, todasTareas),
    );
  }

  Widget _buildTablero(BuildContext context, AgendaEstado estado,
      ColorScheme colors, List<_TareaKanban> todasTareas) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final alturaDisponible = constraints.maxHeight - 16;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columnas(estado).map((col) {
              final tareasCol = todasTareas
                  .where((t) => t.tarea.estado == col.estado)
                  .toList();
              return SizedBox(
                height: alturaDisponible,
                child: _buildColumna(
                    context, estado, col.titulo, col.color, tareasCol, colors),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildColumna(BuildContext context, AgendaEstado estado,
      String titulo, Color color, List<_TareaKanban> tareas, ColorScheme colors) {
    final ancho = esPopup ? 220.0 : 200.0;
    return Container(
      width: ancho,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(titulo, style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${tareas.length}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
          Expanded(
            child: tareas.isEmpty
                ? Center(child: Text('—',
                    style: TextStyle(color: colors.onSurface.withValues(alpha: 0.2))))
                : ListView(
                    padding: const EdgeInsets.all(4),
                    children: tareas.map((t) =>
                        _buildTarjeta(context, estado, t, colors)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjeta(BuildContext context, AgendaEstado estado,
      _TareaKanban tk, ColorScheme colors) {
    return GestureDetector(
      onTap: () => _mostrarMenu(context, estado, tk),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tk.tarea.titulo,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (tk.nombreLista != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(tk.nombreLista!,
                    style: TextStyle(fontSize: 10,
                        color: colors.onSurface.withValues(alpha: 0.5))),
              ),
            if (tk.tarea.persona != null && tk.tarea.persona!.isNotEmpty)
              Text('👤 ${tk.tarea.persona}',
                  style: const TextStyle(fontSize: 10, color: Colors.blue)),
            if (tk.tarea.fechaLimite != null)
              Text('📅 ${tk.tarea.fechaFormateada}',
                  style: TextStyle(fontSize: 10,
                      color: tk.tarea.esPasada ? colors.error : colors.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  void _mostrarMenu(BuildContext context, AgendaEstado estado, _TareaKanban tk) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tk.tarea.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            ..._columnas(estado).where((c) => c.estado != tk.tarea.estado).map((col) =>
              ListTile(
                leading: Container(
                  width: 24, height: 24, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: col.color, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(simboloBujo(col.estado),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col.color)),
                ),
                title: Text(estado.t('kanban.mover_a').replaceAll('{col}', col.titulo)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (tk.origen == 'criticas') {
                    estado.cambiarEstadoCriticaConDatos(tk.index, col.estado);
                  } else {
                    estado.cambiarEstadoListaConDatos(tk.origen, tk.index, col.estado);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TareaKanban {
  final Tarea tarea;
  final String origen;
  final int index;
  final String? nombreLista;
  _TareaKanban(this.tarea, this.origen, this.index, {this.nombreLista});
}
