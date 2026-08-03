import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modelos/lista_personalizada.dart';
import '../modelos/etiqueta.dart';
import '../estado/agenda_estado.dart';

/// Diálogo para crear o editar una lista personalizada.
class DialogoLista extends StatefulWidget {
  final ListaPersonalizada? listaExistente;

  const DialogoLista({super.key, this.listaExistente});

  @override
  State<DialogoLista> createState() => _DialogoListaState();
}

class _DialogoListaState extends State<DialogoLista> {
  late final TextEditingController _nombreCtrl;
  late String _emoji;
  late String _color;

  static const _emojis = [
    '🏥', '🎮', '💼', '🛍️', '🏠', '📚', '💰', '🏋️',
    '🍽️', '🚗', '📞', '✈️', '🎨', '👥', '🔧', '📋',
    '✅', '⭐', '🎯', '🚀',
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.listaExistente;
    _nombreCtrl = TextEditingController(text: l?.nombre ?? '');
    _emoji = l?.emoji ?? '📋';
    _color = l?.color ?? '#667eea';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AgendaEstado>();
    final esEdicion = widget.listaExistente != null;

    return AlertDialog(
      title: Text(esEdicion
          ? '✏️ ${estado.t('dialogo_lista.editar_titulo')}'
          : '📋 ${estado.t('dialogo_lista.nueva_titulo')}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: InputDecoration(
                labelText: estado.t('dialogo_lista.nombre_label'),
                hintText: estado.t('dialogo_lista.nombre_hint'),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Selector de emoji
            Text(estado.t('ajustes.emoji_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _emojis
                  .map((e) => ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 18)),
                        selected: _emoji == e,
                        onSelected: (_) => setState(() => _emoji = e),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Selector de color
            Text(estado.t('ajustes.color_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: coloresDisponibles
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _parseColor(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == c
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: _color == c
                                ? [
                                    BoxShadow(
                                      color: _parseColor(c).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(estado.t('comun.cancelar')),
        ),
        FilledButton(
          onPressed: () {
            final nombre = _nombreCtrl.text.trim();
            if (nombre.isEmpty) return;
            final lista = ListaPersonalizada(
              id: widget.listaExistente?.id,
              nombre: nombre,
              emoji: _emoji,
              color: _color,
              tareas: widget.listaExistente?.tareas ?? [],
              orden: widget.listaExistente?.orden ?? 0,
              fechaCreacion: widget.listaExistente?.fechaCreacion,
            );
            Navigator.pop(context, lista);
          },
          child: Text(esEdicion ? estado.t('comun.guardar') : estado.t('comun.crear')),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}
