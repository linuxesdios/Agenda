import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../estado/agenda_estado.dart';

/// Widget Pomodoro para TDAH — temporizador de concentración.
/// Equivale al modal-pomodoro de la app web.
class SeccionPomodoro extends StatefulWidget {
  const SeccionPomodoro({super.key});

  @override
  State<SeccionPomodoro> createState() => _SeccionPomodoroState();
}

class _SeccionPomodoroState extends State<SeccionPomodoro> {
  final _actividadCtrl = TextEditingController();
  int _duracionMinutos = 25;
  int _segundosRestantes = 0;
  bool _activo = false;
  bool _pausado = false;
  bool _completado = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _actividadCtrl.dispose();
    super.dispose();
  }

  void _iniciar(AgendaEstado estado) {
    if (_actividadCtrl.text.trim().isEmpty) {
      _actividadCtrl.text = estado.t('pomodoro.actividad_sin_especificar');
    }
    setState(() {
      _segundosRestantes = _duracionMinutos * 60;
      _activo = true;
      _pausado = false;
      _completado = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_pausado && _activo) {
        setState(() {
          _segundosRestantes--;
          if (_segundosRestantes <= 0) {
            _completar();
          }
        });
      }
    });
  }

  void _completar() {
    _timer?.cancel();
    setState(() {
      _activo = false;
      _completado = true;
    });
  }

  void _pausar() => setState(() => _pausado = !_pausado);

  void _cancelar() {
    _timer?.cancel();
    setState(() {
      _activo = false;
      _pausado = false;
      _completado = false;
      _segundosRestantes = 0;
    });
  }

  void _reiniciar() {
    setState(() {
      _completado = false;
      _actividadCtrl.clear();
      _duracionMinutos = 25;
    });
  }

  String get _tiempoFormateado {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  double get _progreso {
    if (_duracionMinutos == 0) return 0;
    final total = _duracionMinutos * 60;
    return 1.0 - (_segundosRestantes / total);
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
            color: Colors.red.withValues(alpha: 0.15),
            child: Text(
              '🍅 ${estado.t('pomodoro.titulo')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _completado
                ? _buildCompletado(colors, estado)
                : _activo
                    ? _buildEnCurso(colors, estado)
                    : _buildInicial(colors, estado),
          ),
        ],
      ),
    );
  }

  Widget _buildInicial(ColorScheme colors, AgendaEstado estado) {
    return Column(
      children: [
        TextField(
          controller: _actividadCtrl,
          decoration: InputDecoration(
            labelText: estado.t('pomodoro.en_que_trabajaras'),
            hintText: estado.t('pomodoro.actividad_hint'),
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(estado.t('pomodoro.duracion')),
            Expanded(
              child: Slider(
                value: _duracionMinutos.toDouble(),
                min: 5,
                max: 90,
                divisions: 17,
                label: '$_duracionMinutos min',
                onChanged: (v) =>
                    setState(() => _duracionMinutos = v.toInt()),
              ),
            ),
            Text('$_duracionMinutos min',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _iniciar(estado),
            icon: const Icon(Icons.play_arrow),
            label: Text(estado.t('pomodoro.empezar')),
          ),
        ),
      ],
    );
  }

  Widget _buildEnCurso(ColorScheme colors, AgendaEstado estado) {
    return Column(
      children: [
        Text(
          _actividadCtrl.text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: _progreso,
                  strokeWidth: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              Text(
                _tiempoFormateado,
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _pausar,
              icon: Icon(_pausado ? Icons.play_arrow : Icons.pause),
              label: Text(_pausado ? estado.t('pomodoro.reanudar') : estado.t('pomodoro.pausar')),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _completar,
              icon: const Icon(Icons.stop),
              label: Text(estado.t('pomodoro.terminar')),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _cancelar,
              icon: const Icon(Icons.close),
              tooltip: estado.t('comun.cancelar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletado(ColorScheme colors, AgendaEstado estado) {
    return Column(
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(
          estado.t('pomodoro.completado'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _actividadCtrl.text,
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _reiniciar,
          icon: const Icon(Icons.refresh),
          label: Text(estado.t('pomodoro.nuevo')),
        ),
      ],
    );
  }
}
