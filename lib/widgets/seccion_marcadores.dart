import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../estado/agenda_estado.dart';
import '../modelos/marcador.dart';

/// Sección de marcadores — acceso rápido a sitios web.
class SeccionMarcadores extends StatelessWidget {
  const SeccionMarcadores({super.key});

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.primaryContainer,
            child: Text(
              '🔖 ${estado.t('marcadores.titulo')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          if (estado.marcadores.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(estado.t('marcadores.no_hay'),
                    style: const TextStyle(color: Colors.grey)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(estado.marcadores.length, (i) {
                  final m = estado.marcadores[i];
                  return _buildChipMarcador(context, estado, m, i, colors);
                }),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () =>
                  _agregarMarcador(context, estado),
              icon: const Icon(Icons.add, size: 18),
              label: Text(estado.t('marcadores.anadir')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipMarcador(BuildContext context, AgendaEstado estado,
      Marcador m, int index, ColorScheme colors) {
    return GestureDetector(
      onLongPress: () => _menuMarcador(context, estado, m, index),
      child: ActionChip(
        avatar: Text(m.icono, style: const TextStyle(fontSize: 16)),
        label: Text(m.nombre),
        onPressed: () => _abrirUrl(m.url),
        tooltip: m.url,
      ),
    );
  }

  Future<void> _abrirUrl(String url) async {
    var uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _menuMarcador(BuildContext context, AgendaEstado estado,
      Marcador m, int index) async {
    final accion = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${m.icono} ${m.nombre}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'editar'),
            child: Text('✏️ ${estado.t('comun.editar')}'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'eliminar'),
            child: Text('🗑️ ${estado.t('comun.eliminar')}'),
          ),
        ],
      ),
    );
    if (accion == 'editar') {
      if (!context.mounted) return;
      await _editarMarcador(context, estado, m, index);
    } else if (accion == 'eliminar') {
      await estado.eliminarMarcador(index);
    }
  }

  Future<void> _agregarMarcador(
      BuildContext context, AgendaEstado estado) async {
    final resultado = await _mostrarDialogoMarcador(context, estado);
    if (resultado != null) {
      await estado.agregarMarcador(resultado);
    }
  }

  Future<void> _editarMarcador(BuildContext context, AgendaEstado estado,
      Marcador m, int index) async {
    final resultado =
        await _mostrarDialogoMarcador(context, estado, existente: m);
    if (resultado != null) {
      await estado.editarMarcador(index, resultado);
    }
  }

  Future<Marcador?> _mostrarDialogoMarcador(
      BuildContext context, AgendaEstado estado,
      {Marcador? existente}) async {
    final nombreCtrl =
        TextEditingController(text: existente?.nombre ?? '');
    final urlCtrl = TextEditingController(text: existente?.url ?? '');
    String icono = existente?.icono ?? '🔗';

    const iconos = [
      '🔗', '🌐', '📧', '📱', '💼', '🏦', '🛒', '📚',
      '🎮', '🎵', '📺', '☁️', '🔧', '📰', '🏥', '✈️',
    ];

    return showDialog<Marcador>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existente != null
              ? '✏️ ${estado.t('marcadores.editar_titulo')}'
              : '🔖 ${estado.t('marcadores.nuevo_titulo')}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: estado.t('principal.nombre_label'),
                  hintText: estado.t('marcadores.nombre_hint'),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: iconos
                    .map((e) => ChoiceChip(
                          label: Text(e),
                          selected: icono == e,
                          onSelected: (_) =>
                              setLocal(() => icono = e),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(estado.t('comun.cancelar')),
            ),
            FilledButton(
              onPressed: () {
                if (nombreCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
                Navigator.pop(
                  ctx,
                  Marcador(
                    id: existente?.id,
                    nombre: nombreCtrl.text.trim(),
                    url: urlCtrl.text.trim(),
                    icono: icono,
                  ),
                );
              },
              child: Text(estado.t('comun.guardar')),
            ),
          ],
        ),
      ),
    );
  }
}
