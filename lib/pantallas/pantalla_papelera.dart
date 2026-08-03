import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';

class PantallaPapelera extends StatelessWidget {
  const PantallaPapelera({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;
    final items = estado.papelera;

    return Scaffold(
      appBar: AppBar(
        title: Text('🗑️ ${estado.t('papelera.titulo')} (${items.length})'),
        backgroundColor: colors.primaryContainer,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: estado.t('papelera.vaciar_tooltip'),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(estado.t('papelera.vaciar_dialogo_titulo')),
                    content: Text(estado.t('papelera.vaciar_dialogo_contenido')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: Text(estado.t('comun.cancelar'))),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: colors.error),
                          child: Text(estado.t('papelera.vaciar_boton'))),
                    ],
                  ),
                );
                if (ok == true) await estado.vaciarPapelera();
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(child: Text(estado.t('papelera.vacia'),
              style: const TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final elem = items[i];
                final icono = switch (elem.tipo) {
                  'tarea_critica' => '🚨',
                  'tarea_lista' => '📋',
                  'cita' => '📅',
                  _ => '📄',
                };
                return Card(
                  child: ListTile(
                    leading: Text(icono, style: const TextStyle(fontSize: 20)),
                    title: Text(elem.titulo),
                    subtitle: Text(
                      estado.t('papelera.eliminado_info')
                          .replaceAll('{fecha}', elem.fechaLegible)
                          .replaceAll('{dias}', '${elem.diasRestantes}'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          tooltip: estado.t('papelera.restaurar_tooltip'),
                          onPressed: () => estado.restaurarDePapelera(i),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: colors.error),
                          tooltip: estado.t('papelera.borrar_definitivo_tooltip'),
                          onPressed: () => estado.eliminarDePapelera(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
