import '../i18n/idioma.dart';
import '../i18n/traducciones.dart';

/// Configuración visual por dispositivo.
/// Cada dispositivo (PC, móvil) tiene su propia configuración visual,
/// pero comparten los mismos datos (tareas, citas, etc.).
class Configuracion {
  bool modoOscuro;
  String titulo;
  String paleta;
  int columnas;
  String distribucion;
  String dispositivoNombre;

  /// Tamaño de fuente base (14 = normal). Rango: 10-24.
  double tamanoLetra;

  /// Emoji que se muestra como icono en el AppBar junto al título.
  String iconoApp;

  /// Frases motivacionales separadas por salto de línea.
  /// Se muestran aleatoriamente debajo del título.
  String frases;

  /// Código de idioma de la interfaz ('es', 'en', 'ru', 'zh').
  /// null = todavía no se detectó/eligió (primer arranque).
  String? idioma;

  Configuracion({
    this.modoOscuro = false,
    this.titulo = 'Agenda',
    this.paleta = 'verde',
    this.columnas = 1,
    this.distribucion = defaultDist,
    this.dispositivoNombre = '',
    this.tamanoLetra = 14,
    this.iconoApp = '📋',
    this.frases = _defaultFrases,
    this.idioma,
    this.resumenDiario = true,
    this.recordatoriosPorDefecto = const [15],
    this.widgetMostrarCriticas = true,
    this.widgetMostrarCitas = true,
    this.widgetMostrarHoy = true,
    this.widgetMostrarListas = false,
  });

  /// Si true, muestra un popup con el resumen del día al abrir la app.
  bool resumenDiario;

  /// Minutos antes para avisar de citas (por defecto en nuevas citas).
  /// Ej: [15] = 15 min; [15, 60, 1440] = 15min + 1h + 1día.
  List<int> recordatoriosPorDefecto;

  /// Qué secciones mostrar en el widget de pantalla de inicio de Android.
  bool widgetMostrarCriticas;
  bool widgetMostrarCitas;
  bool widgetMostrarHoy;
  bool widgetMostrarListas;

  static const _defaultFrases =
      'El éxito es la suma de pequeños esfuerzos repetidos día tras día\n'
      'No dejes para mañana lo que puedes hacer hoy\n'
      'Cada tarea completada es un paso hacia tu meta\n'
      'La constancia vence lo que la dicha no alcanza';

  static const defaultDist =
      'criticas:full,citas:full,listas:full,pomodoro:full,'
      'notas:full,sentimientos:full,marcadores:full,contrasenas:full';

  List<({String seccion, String ubicacion})> get distribucionParseada {
    final resultado = <({String seccion, String ubicacion})>[];
    for (final parte in distribucion.split(',')) {
      final p = parte.trim();
      if (p.isEmpty) continue;
      final sep = p.indexOf(':');
      if (sep == -1) {
        resultado.add((seccion: p, ubicacion: 'full'));
      } else {
        resultado.add((
          seccion: p.substring(0, sep),
          ubicacion: p.substring(sep + 1),
        ));
      }
    }
    for (final sec in idsSecciones) {
      if (!resultado.any((r) => r.seccion == sec)) {
        resultado.add((seccion: sec, ubicacion: 'full'));
      }
    }
    return resultado;
  }

  static String serializarDistribucion(
      List<({String seccion, String ubicacion})> dist) {
    return dist.map((d) => '${d.seccion}:${d.ubicacion}').join(',');
  }

  /// Devuelve una frase aleatoria de la lista configurada.
  String get fraseAleatoria {
    final lista = frases
        .split('\n')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    if (lista.isEmpty) return '';
    return lista[DateTime.now().millisecond % lista.length];
  }

  Map<String, dynamic> toJson() => {
        'modoOscuro': modoOscuro,
        'titulo': titulo,
        'paleta': paleta,
        'columnas': columnas,
        'distribucion': distribucion,
        'dispositivoNombre': dispositivoNombre,
        'tamanoLetra': tamanoLetra,
        'iconoApp': iconoApp,
        'frases': frases,
        'idioma': idioma,
        'resumenDiario': resumenDiario,
        'recordatoriosPorDefecto': recordatoriosPorDefecto,
        'widgetMostrarCriticas': widgetMostrarCriticas,
        'widgetMostrarCitas': widgetMostrarCitas,
        'widgetMostrarHoy': widgetMostrarHoy,
        'widgetMostrarListas': widgetMostrarListas,
      };

  factory Configuracion.fromJson(Map<String, dynamic> json) => Configuracion(
        modoOscuro: json['modoOscuro'] as bool? ?? false,
        titulo: json['titulo'] as String? ?? 'Agenda',
        paleta: json['paleta'] ?? json['tema'] as String? ?? 'verde',
        columnas: json['columnas'] as int? ?? 1,
        distribucion: json['distribucion'] as String? ?? defaultDist,
        dispositivoNombre: json['dispositivoNombre'] as String? ?? '',
        tamanoLetra: (json['tamanoLetra'] as num?)?.toDouble() ?? 14,
        iconoApp: json['iconoApp'] as String? ?? '📋',
        frases: json['frases'] as String? ?? _defaultFrases,
        idioma: json['idioma'] as String?,
        resumenDiario: json['resumenDiario'] as bool? ?? true,
        recordatoriosPorDefecto:
            (json['recordatoriosPorDefecto'] as List<dynamic>?)
                    ?.map((e) => e as int)
                    .toList() ??
                [15],
        widgetMostrarCriticas: json['widgetMostrarCriticas'] as bool? ?? true,
        widgetMostrarCitas: json['widgetMostrarCitas'] as bool? ?? true,
        widgetMostrarHoy: json['widgetMostrarHoy'] as bool? ?? true,
        widgetMostrarListas: json['widgetMostrarListas'] as bool? ?? false,
      );
}

const Map<String, ({String emoji, int seedColor})> paletasDisponibles = {
  'verde': (emoji: '🌿', seedColor: 0xFF4ECDC4),
  'azul': (emoji: '💙', seedColor: 0xFF2196F3),
  'amarillo': (emoji: '💛', seedColor: 0xFFFFB300),
  'purpura': (emoji: '💜', seedColor: 0xFF7C4DFF),
  'rosa': (emoji: '💗', seedColor: 0xFFE91E63),
  'naranja': (emoji: '🧡', seedColor: 0xFFFF6D00),
};

/// Nombre traducido de una paleta, con su emoji. Ej: "🌿 Verde" / "🌿 Green".
String nombrePaleta(String id, Idioma idioma) {
  final emoji = paletasDisponibles[id]?.emoji ?? '';
  return '$emoji ${Traducciones.t(idioma, 'paleta.$id')}'.trim();
}

const Map<String, String> emojiSecciones = {
  'criticas': '🚨',
  'citas': '📅',
  'calendario': '📅',
  'listas': '📋',
  'notas': '📝',
  'sentimientos': '😊',
  'pomodoro': '🍅',
  'marcadores': '🔖',
  'contrasenas': '🔐',
  'semanal': '📅',
};

/// IDs de sección válidos, en el orden por defecto. Reemplaza a las keys
/// del viejo `nombresSecciones` para código que solo necesita iterar IDs.
const List<String> idsSecciones = [
  'criticas', 'citas', 'calendario', 'listas', 'notas',
  'sentimientos', 'pomodoro', 'marcadores', 'contrasenas', 'semanal',
];

/// Nombre traducido de una sección, con su emoji. Ej: "🚨 Tareas Críticas".
String nombreSeccion(String id, Idioma idioma) {
  final emoji = emojiSecciones[id] ?? '';
  return '$emoji ${Traducciones.t(idioma, 'seccion.$id')}'.trim();
}
