import 'tarea.dart';
import 'lista_personalizada.dart';
import 'etiqueta.dart';
import 'configuracion.dart';
import 'cita.dart';
import 'contrasena.dart';
import 'marcador.dart';
import 'papelera.dart';
import 'plantilla.dart';

/// Contenedor raíz con TODOS los datos de la agenda.
/// Es lo que se serializa/deserializa completo en el archivo JSON.
class DatosAgenda {
  List<Tarea> tareasCriticas;
  List<ListaPersonalizada> listasPersonalizadas;
  List<Etiqueta> etiquetas;
  List<String> personas;
  Configuracion configuracion;
  List<Cita> citas;
  String notas;
  String sentimientos;
  List<Contrasena> contrasenas;
  List<Marcador> marcadores;
  List<ElementoPapelera> papelera;
  List<PlantillaTarea> plantillas;

  DatosAgenda({
    List<Tarea>? tareasCriticas,
    List<ListaPersonalizada>? listasPersonalizadas,
    List<Etiqueta>? etiquetas,
    List<String>? personas,
    Configuracion? configuracion,
    List<Cita>? citas,
    this.notas = '',
    this.sentimientos = '',
    List<Contrasena>? contrasenas,
    List<Marcador>? marcadores,
    List<ElementoPapelera>? papelera,
    List<PlantillaTarea>? plantillas,
  })  : tareasCriticas = tareasCriticas ?? [],
        listasPersonalizadas = listasPersonalizadas ?? [],
        etiquetas = etiquetas ?? [],
        personas = personas ?? [],
        configuracion = configuracion ?? Configuracion(),
        citas = citas ?? [],
        contrasenas = contrasenas ?? [],
        marcadores = marcadores ?? [],
        papelera = papelera ?? [],
        plantillas = plantillas ?? [];

  Map<String, dynamic> toJson() => {
        'tareasCriticas': tareasCriticas.map((t) => t.toJson()).toList(),
        'listasPersonalizadas':
            listasPersonalizadas.map((l) => l.toJson()).toList(),
        'etiquetas': etiquetas.map((e) => e.toJson()).toList(),
        'personas': personas,
        'configuracion': configuracion.toJson(),
        'citas': citas.map((c) => c.toJson()).toList(),
        'notas': notas,
        'sentimientos': sentimientos,
        'contrasenas': contrasenas.map((c) => c.toJson()).toList(),
        'marcadores': marcadores.map((m) => m.toJson()).toList(),
        'papelera': papelera.map((p) => p.toJson()).toList(),
        'plantillas': plantillas.map((p) => p.toJson()).toList(),
      };

  factory DatosAgenda.fromJson(Map<String, dynamic> json) => DatosAgenda(
        tareasCriticas: (json['tareasCriticas'] as List<dynamic>?)
                ?.map((t) => Tarea.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        listasPersonalizadas:
            (json['listasPersonalizadas'] as List<dynamic>?)
                    ?.map((l) =>
                        ListaPersonalizada.fromJson(l as Map<String, dynamic>))
                    .toList() ??
                [],
        etiquetas: (json['etiquetas'] as List<dynamic>?)
                ?.map((e) => Etiqueta.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        personas: (json['personas'] as List<dynamic>?)
                ?.map((p) => p as String)
                .toList() ??
            [],
        configuracion: json['configuracion'] != null
            ? Configuracion.fromJson(
                json['configuracion'] as Map<String, dynamic>)
            : Configuracion(),
        citas: (json['citas'] as List<dynamic>?)
                ?.map((c) => Cita.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        notas: json['notas'] as String? ?? '',
        sentimientos: json['sentimientos'] as String? ?? '',
        contrasenas: (json['contrasenas'] as List<dynamic>?)
                ?.map((c) => Contrasena.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        marcadores: (json['marcadores'] as List<dynamic>?)
                ?.map((m) => Marcador.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        papelera: (json['papelera'] as List<dynamic>?)
                ?.map((p) => ElementoPapelera.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        plantillas: (json['plantillas'] as List<dynamic>?)
                ?.map((p) => PlantillaTarea.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
