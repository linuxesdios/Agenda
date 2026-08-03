import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../estado/agenda_estado.dart';
import '../modelos/tarea.dart';
import '../i18n/calendario_i18n.dart';
import '../i18n/idioma.dart';

/// Muestra el resumen del día si:
/// 1. La config resumenDiario está activada
/// 2. Son las 5:00 AM o más
/// 3. No se ha mostrado ya hoy
Future<void> mostrarResumenSiCorresponde(
    BuildContext context, AgendaEstado estado) async {
  if (!estado.configuracion.resumenDiario) return;

  final ahora = DateTime.now();
  if (ahora.hour < 5) return;

  final hoyStr = '${ahora.year}${ahora.month}${ahora.day}';
  final yaVisto = await _leerUltimoResumen();
  if (yaVisto == hoyStr) return;

  await _guardarUltimoResumen(hoyStr);

  if (!context.mounted) return;

  final hoyFecha =
      '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';

  final tareasHoy = <Tarea>[];
  final tareasVencidas = <Tarea>[];

  for (final t in estado.tareasCriticas) {
    if (t.completada) continue;
    if (t.soloFecha == hoyFecha) {
      tareasHoy.add(t);
    } else if (t.esPasada) {
      tareasVencidas.add(t);
    }
  }
  for (final lista in estado.listasPersonalizadas) {
    for (final t in lista.tareas) {
      if (t.completada) continue;
      if (t.soloFecha == hoyFecha) {
        tareasHoy.add(t);
      } else if (t.esPasada) {
        tareasVencidas.add(t);
      }
    }
  }

  final citasHoy = estado.citasDelDia(hoyFecha);
  final hayAlgo =
      tareasHoy.isNotEmpty || tareasVencidas.isNotEmpty || citasHoy.isNotEmpty;

  final diasSemana = CalendarioI18n.diasCompletos(estado.idioma);
  final meses = CalendarioI18n.mesesCompletos(estado.idioma);
  // Simplificación: mismo orden "díaSemana día mes" en todos los idiomas
  // (en español agrega el conector "de"; no es 100% idiomático en los demás
  // pero mantiene el mecanismo simple, sin reglas gramaticales por idioma).
  final fechaLegible = estado.idioma.codigo == 'es'
      ? '${diasSemana[ahora.weekday - 1]} ${ahora.day} de ${meses[ahora.month - 1]}'
      : '${diasSemana[ahora.weekday - 1]} ${ahora.day} ${meses[ahora.month - 1]}';

  showDialog(
    context: context,
    builder: (ctx) {
      final colors = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text('📋 ${estado.t('resumen.titulo').replaceAll('{fecha}', fechaLegible)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hayAlgo) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(estado.t('resumen.nada_hoy'),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('"${estado.configuracion.fraseAleatoria}"',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: colors.onSurface.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],

              // Citas de hoy
              if (citasHoy.isNotEmpty) ...[
                Text('🕐 ${estado.t('resumen.citas_hoy')}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.primary)),
                const SizedBox(height: 4),
                ...citasHoy.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Text('${c.hora}  ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.primary)),
                        Expanded(child: Text(c.descripcion)),
                      ]),
                    )),
                const SizedBox(height: 12),
              ],

              // Tareas de hoy
              if (tareasHoy.isNotEmpty) ...[
                Text('📌 ${estado.t('resumen.tareas_hoy')}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.primary)),
                const SizedBox(height: 4),
                ...tareasHoy.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Text('●  '),
                        Expanded(child: Text(t.titulo)),
                        if (t.soloHora != null)
                          Text('  ${t.soloHora}',
                              style: TextStyle(
                                  fontSize: 12, color: colors.primary)),
                      ]),
                    )),
                const SizedBox(height: 12),
              ],

              // Tareas vencidas
              if (tareasVencidas.isNotEmpty) ...[
                Text('⚠️ ${estado.t('resumen.tareas_vencidas').replaceAll('{n}', '${tareasVencidas.length}')}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.red)),
                const SizedBox(height: 4),
                ...tareasVencidas.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Text('⚠️ ',
                            style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(t.titulo,
                              style: const TextStyle(color: Colors.red)),
                        ),
                        Text('  ${t.fechaFormateada}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.red)),
                      ]),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(estado.t('resumen.entendido')),
          ),
        ],
      );
    },
  );
}

Future<String> _leerUltimoResumen() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final f =
        File('${dir.path}${Platform.pathSeparator}agenda_resumen.txt');
    if (await f.exists()) return (await f.readAsString()).trim();
  } catch (_) {}
  return '';
}

Future<void> _guardarUltimoResumen(String valor) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final f =
        File('${dir.path}${Platform.pathSeparator}agenda_resumen.txt');
    await f.writeAsString(valor);
  } catch (_) {}
}
