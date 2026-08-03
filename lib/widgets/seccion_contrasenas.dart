import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/contrasena.dart';
import '../servicios/servicio_cripto.dart';

/// Sección de contraseñas encriptadas con AES-256-GCM.
/// Requiere contraseña maestra para ver/añadir contraseñas.
class SeccionContrasenas extends StatefulWidget {
  const SeccionContrasenas({super.key});

  @override
  State<SeccionContrasenas> createState() => _SeccionContrasenasState();
}

class _SeccionContrasenasState extends State<SeccionContrasenas> {
  String? _passwordMaestra;
  bool _sesionActiva = false;

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
            color: colors.error.withValues(alpha: 0.15),
            child: Row(
              children: [
                Text(
                  '🔐 ${estado.t('contrasenas.titulo')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (_sesionActiva)
                  IconButton(
                    icon: const Icon(Icons.lock, size: 20),
                    tooltip: estado.t('contrasenas.cerrar_sesion_tooltip'),
                    onPressed: () => setState(() {
                      _passwordMaestra = null;
                      _sesionActiva = false;
                    }),
                  ),
              ],
            ),
          ),
          if (!_sesionActiva) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    estado.t('contrasenas.intro_password'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _solicitarPassword(context),
                    icon: const Icon(Icons.lock_open),
                    label: Text(estado.t('contrasenas.desbloquear')),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...List.generate(estado.contrasenas.length, (index) {
              return _buildTarjetaContrasena(
                  context, estado, estado.contrasenas[index], index, colors);
            }),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () =>
                    _agregarContrasena(context, estado),
                icon: const Icon(Icons.add, size: 18),
                label: Text(estado.t('contrasenas.nueva')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTarjetaContrasena(BuildContext context, AgendaEstado estado,
      Contrasena c, int index, ColorScheme colors) {
    return ListTile(
      leading: const Icon(Icons.key),
      title: Text(c.nombre),
      subtitle: const Text('••••••••'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            tooltip: estado.t('contrasenas.ver_tooltip'),
            onPressed: () => _verContrasena(context, estado, c),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: estado.t('contrasenas.copiar_tooltip'),
            onPressed: () => _copiarContrasena(context, estado, c),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
            onPressed: () => estado.eliminarContrasena(index),
          ),
        ],
      ),
    );
  }

  Future<void> _solicitarPassword(BuildContext context) async {
    final estado = context.read<AgendaEstado>();
    final ctrl = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🔐 ${estado.t('contrasenas.password_maestra_titulo')}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: estado.t('contrasenas.password_maestra_label'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(estado.t('comun.cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(estado.t('contrasenas.desbloquear')),
          ),
        ],
      ),
    );
    if (password != null && password.isNotEmpty) {
      setState(() {
        _passwordMaestra = password;
        _sesionActiva = true;
      });
    }
  }

  Future<void> _verContrasena(BuildContext context, AgendaEstado estado, Contrasena c) async {
    if (_passwordMaestra == null) return;
    try {
      final valor =
          await ServicioCripto.desencriptar(c.valorEncriptado, _passwordMaestra!);
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(c.nombre),
          content: SelectableText(
            valor,
            style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: valor));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(estado.t('contrasenas.copiada_portapapeles'))),
                );
              },
              child: Text(estado.t('contrasenas.copiar_tooltip')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(estado.t('comun.cerrar')),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estado.t('contrasenas.password_incorrecta'))),
      );
    }
  }

  Future<void> _copiarContrasena(BuildContext context, AgendaEstado estado, Contrasena c) async {
    if (_passwordMaestra == null) return;
    try {
      final valor =
          await ServicioCripto.desencriptar(c.valorEncriptado, _passwordMaestra!);
      await Clipboard.setData(ClipboardData(text: valor));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estado.t('contrasenas.copiada_portapapeles'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(estado.t('contrasenas.password_incorrecta'))),
      );
    }
  }

  Future<void> _agregarContrasena(
      BuildContext context, AgendaEstado estado) async {
    if (_passwordMaestra == null) return;
    final nombreCtrl = TextEditingController();
    final valorCtrl = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🔐 ${estado.t('contrasenas.nueva')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: estado.t('principal.nombre_label'),
                hintText: estado.t('contrasenas.nombre_hint'),
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorCtrl,
              decoration: InputDecoration(
                labelText: estado.t('contrasenas.password_a_guardar'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(estado.t('comun.cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(estado.t('comun.guardar')),
          ),
        ],
      ),
    );

    if (resultado == true &&
        nombreCtrl.text.isNotEmpty &&
        valorCtrl.text.isNotEmpty) {
      final encriptado = await ServicioCripto.encriptar(
          valorCtrl.text, _passwordMaestra!);
      await estado.agregarContrasena(Contrasena(
        nombre: nombreCtrl.text.trim(),
        valorEncriptado: encriptado,
      ));
    }
  }
}
