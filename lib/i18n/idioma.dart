import 'dart:ui';

/// Idiomas soportados por la app.
enum Idioma { es, en, ru, zh }

extension IdiomaInfo on Idioma {
  String get codigo => switch (this) {
        Idioma.es => 'es',
        Idioma.en => 'en',
        Idioma.ru => 'ru',
        Idioma.zh => 'zh',
      };

  /// Nombre del idioma en su propio idioma, para mostrar en el selector.
  String get nombreNativo => switch (this) {
        Idioma.es => 'Español',
        Idioma.en => 'English',
        Idioma.ru => 'Русский',
        Idioma.zh => '中文',
      };
}

Idioma? idiomaDesdeCodigo(String? codigo) => switch (codigo) {
      'es' => Idioma.es,
      'en' => Idioma.en,
      'ru' => Idioma.ru,
      'zh' => Idioma.zh,
      _ => null,
    };

/// Detecta el idioma del sistema operativo. Si no es uno de los soportados,
/// usa español por defecto.
Idioma detectarIdiomaDelSistema() {
  final codigo = PlatformDispatcher.instance.locale.languageCode;
  return idiomaDesdeCodigo(codigo) ?? Idioma.es;
}
