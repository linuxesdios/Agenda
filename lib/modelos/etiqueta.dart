/// Etiqueta para categorizar tareas (y en el futuro, citas).
/// Cada etiqueta tiene nombre, emoji y color.
class Etiqueta {
  String nombre;
  String emoji;

  /// Color en formato hex, ej: '#4ecdc4'.
  String color;

  /// 'tareas' o 'citas' — distingue para qué sección se usa.
  String tipo;

  Etiqueta({
    required this.nombre,
    this.emoji = '📌',
    this.color = '#4ecdc4',
    this.tipo = 'tareas',
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'emoji': emoji,
        'color': color,
        'tipo': tipo,
      };

  factory Etiqueta.fromJson(Map<String, dynamic> json) => Etiqueta(
        nombre: json['nombre'] as String? ?? '',
        emoji: (json['emoji'] ?? json['simbolo']) as String? ?? '📌',
        color: json['color'] as String? ?? '#4ecdc4',
        tipo: json['tipo'] as String? ?? 'tareas',
      );

  @override
  String toString() => '$emoji $nombre';
}

/// Emojis predefinidos para elegir al crear etiquetas.
const List<String> emojisDisponibles = [
  '💼', '🏥', '🎮', '📚', '🏠', '💰', '🚗', '🍽️',
  '📞', '🛍️', '✈️', '📱', '🏋️', '📝', '🎉', '👥',
  '🎨', '🔧', '🌱', '📧', '⚡', '🚀', '🌟', '💡',
  '🔥', '💪', '🏆', '📌', '🎯', '📋',
];

/// Colores predefinidos para elegir al crear etiquetas.
const List<String> coloresDisponibles = [
  '#4ecdc4', '#ff6b6b', '#ffd93d', '#6c5ce7', '#a8e6cf',
  '#ff8a80', '#82b1ff', '#b388ff', '#f48fb1', '#80cbc4',
  '#ffcc80', '#a5d6a7', '#ef9a9a', '#90caf9', '#ce93d8',
];
