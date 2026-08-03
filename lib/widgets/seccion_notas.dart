import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';

/// Sección de Notas / Brain Dump — texto libre persistido.
class SeccionNotas extends StatefulWidget {
  const SeccionNotas({super.key});

  @override
  State<SeccionNotas> createState() => _SeccionNotasState();
}

class _SeccionNotasState extends State<SeccionNotas> {
  late final TextEditingController _ctrl;
  bool _modificado = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: context.read<AgendaEstado>().notas);
  }

  @override
  void dispose() {
    if (_modificado) {
      context.read<AgendaEstado>().guardarNotas(_ctrl.text);
    }
    _ctrl.dispose();
    super.dispose();
  }

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
            color: colors.tertiaryContainer,
            child: Text(
              '📝 ${estado.t('notas.titulo')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onTertiaryContainer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                hintText: estado.t('notas.hint'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                _modificado = true;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: FilledButton.tonal(
              onPressed: () {
                context
                    .read<AgendaEstado>()
                    .guardarNotas(_ctrl.text);
                _modificado = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(estado.t('notas.guardadas')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(estado.t('notas.guardar')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de Sentimientos — texto libre persistido.
class SeccionSentimientos extends StatefulWidget {
  const SeccionSentimientos({super.key});

  @override
  State<SeccionSentimientos> createState() => _SeccionSentimientosState();
}

class _SeccionSentimientosState extends State<SeccionSentimientos> {
  late final TextEditingController _ctrl;
  bool _modificado = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: context.read<AgendaEstado>().sentimientos);
  }

  @override
  void dispose() {
    if (_modificado) {
      context.read<AgendaEstado>().guardarSentimientos(_ctrl.text);
    }
    _ctrl.dispose();
    super.dispose();
  }

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
            color: colors.secondaryContainer,
            child: Text(
              '😊 ${estado.t('sentimientos.titulo')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                hintText: estado.t('sentimientos.hint'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                _modificado = true;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: FilledButton.tonal(
              onPressed: () {
                context
                    .read<AgendaEstado>()
                    .guardarSentimientos(_ctrl.text);
                _modificado = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(estado.t('sentimientos.guardadas')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Text(estado.t('comun.guardar')),
            ),
          ),
        ],
      ),
    );
  }
}
