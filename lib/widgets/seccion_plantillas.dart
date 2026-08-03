import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/plantilla.dart';

class SeccionPlantillas extends StatelessWidget {
  const SeccionPlantillas({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colors.tertiaryContainer,
            child: Text('📋 ${estado.t('plantillas.titulo')}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: colors.onTertiaryContainer)),
          ),
          if (estado.plantillas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text(estado.t('plantillas.sin_plantillas'),
                  style: const TextStyle(color: Colors.grey))),
            )
          else
            ...List.generate(estado.plantillas.length, (i) {
              final p = estado.plantillas[i];
              return ListTile(
                dense: true,
                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${p.subtareasTexto.length} subtareas: ${p.subtareasTexto.take(3).join(", ")}${p.subtareasTexto.length > 3 ? "..." : ""}',
                    style: const TextStyle(fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _usarPlantilla(context, estado, i),
                      child: Text(estado.t('plantillas.usar')),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
                      onPressed: () => estado.eliminarPlantilla(i),
                    ),
                  ],
                ),
              );
            }),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () => _crearPlantilla(context, estado),
              icon: const Icon(Icons.add, size: 18),
              label: Text(estado.t('plantillas.nueva')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearPlantilla(BuildContext context, AgendaEstado estado) async {
    final nombreCtrl = TextEditingController();
    final subtareasCtrl = TextEditingController();

    final resultado = await showDialog<PlantillaTarea>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, minWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 ${estado.t('plantillas.nueva')}',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: estado.t('plantillas.nombre_label'),
                    hintText: estado.t('principal.nombre_hint_rutina'),
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtareasCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: estado.t('principal.subtareas_label'),
                    hintText: estado.t('principal.subtareas_hint'),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx),
                        child: Text(estado.t('comun.cancelar'))),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final nombre = nombreCtrl.text.trim();
                        if (nombre.isEmpty) return;
                        final subs = subtareasCtrl.text
                            .split('\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        Navigator.pop(ctx, PlantillaTarea(
                            nombre: nombre, subtareasTexto: subs));
                      },
                      child: Text(estado.t('comun.crear')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (resultado != null) await estado.agregarPlantilla(resultado);
  }

  Future<void> _usarPlantilla(BuildContext context, AgendaEstado estado, int index) async {
    final listas = estado.listasPersonalizadas;
    String destino = 'criticas';

    if (listas.isNotEmpty) {
      final sel = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(estado.t('principal.donde_crear_tarea')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'criticas'),
              child: Text('🚨 ${estado.t('principal.tareas_criticas')}'),
            ),
            ...listas.map((l) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l.id),
              child: Text('${l.emoji} ${l.nombre}'),
            )),
          ],
        ),
      );
      if (sel == null) return;
      destino = sel;
    }

    await estado.usarPlantilla(index, destino: destino);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(estado.t('plantillas.tarea_creada')
          .replaceAll('{nombre}', estado.plantillas[index].nombre))),
    );
  }
}
