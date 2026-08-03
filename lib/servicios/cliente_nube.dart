import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Cliente para sincronizar con GitHub Gist (privado).
///
/// Usa dart:io HttpClient en vez de package:http para poder
/// desactivar la verificación SSL en PCs con certificados
/// corporativos o antivirus que interceptan HTTPS.
class ClienteNube {
  final String token;
  final String gistId;

  static const _baseUrl = 'https://api.github.com/gists';
  static const _nombreArchivo = 'agenda_sync.json';

  ClienteNube({required this.token, required this.gistId});

  /// HttpClient que acepta cualquier certificado SSL.
  static HttpClient _crearCliente() {
    final client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }

  Future<String> _request(String method, String url,
      {String? body}) async {
    final client = _crearCliente();
    try {
      final request = await client.openUrl(method, Uri.parse(url));
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('Authorization', 'token $token');
      if (body != null) {
        final bytes = utf8.encode(body);
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.headers.set('Content-Length', '${bytes.length}');
        request.add(bytes);
      }
      final response = await request.close();
      final responseBody =
          await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        throw Exception(
            'HTTP ${response.statusCode}: ${responseBody.length > 200 ? responseBody.substring(0, 200) : responseBody}');
      }
      return responseBody;
    } finally {
      client.close();
    }
  }

  Future<void> subir(String contenido) async {
    // GitHub Gist espera content como string plano.
    // Construimos el JSON del body usando el Map para que
    // jsonEncode maneje el escape correctamente.
    final body = {
      'files': {
        _nombreArchivo: {'content': contenido}
      }
    };
    await _request('PATCH', '$_baseUrl/$gistId',
        body: jsonEncode(body));
  }

  Future<({String contenido, int fechaModificacion})> descargar() async {
    final responseBody = await _request('GET', '$_baseUrl/$gistId');
    final json = jsonDecode(responseBody);
    final files = json['files'] as Map<String, dynamic>;
    final archivo = files[_nombreArchivo] as Map<String, dynamic>?;
    if (archivo == null) {
      throw Exception('El gist no contiene $_nombreArchivo');
    }
    final contenido = archivo['content'] as String;
    try {
      final datos = jsonDecode(contenido);
      final lastMod = datos['lastModified'] as int? ?? 0;
      return (contenido: contenido, fechaModificacion: lastMod);
    } catch (_) {
      return (contenido: contenido, fechaModificacion: 0);
    }
  }

  /// Lista las versiones anteriores del Gist (historial de commits).
  Future<List<({String version, DateTime fecha, String dispositivoOrigen})>>
      listarHistorial() async {
    final responseBody = await _request('GET', '$_baseUrl/$gistId');
    final json = jsonDecode(responseBody);
    final history = json['history'] as List<dynamic>? ?? [];
    final resultado =
        <({String version, DateTime fecha, String dispositivoOrigen})>[];
    for (final h in history) {
      final version = h['version'] as String? ?? '';
      final fechaStr = h['committed_at'] as String? ?? '';
      final fecha = DateTime.tryParse(fechaStr) ?? DateTime.now();
      resultado.add((
        version: version,
        fecha: fecha.toLocal(),
        dispositivoOrigen: '',
      ));
    }
    return resultado;
  }

  /// Descarga una versión específica del Gist por su commit SHA.
  Future<String> descargarVersion(String version) async {
    final responseBody = await _request('GET', '$_baseUrl/$gistId/$version');
    final json = jsonDecode(responseBody);
    final files = json['files'] as Map<String, dynamic>;
    final archivo = files[_nombreArchivo] as Map<String, dynamic>?;
    if (archivo == null) throw Exception('Versión sin $_nombreArchivo');
    return archivo['content'] as String;
  }

  static Future<String> crearGist(String token) async {
    final client = _crearCliente();
    try {
      final request =
          await client.openUrl('POST', Uri.parse(_baseUrl));
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('Authorization', 'token $token');
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'description': 'Agenda sync - no borrar',
        'public': false,
        'files': {
          _nombreArchivo: {
            'content': jsonEncode({
              'schemaVersion': 1,
              'lastModified': 0,
              'dispositivoOrigen': '',
              'datos': {},
            })
          }
        }
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 201) {
        throw Exception('Error creando gist (${response.statusCode})');
      }
      final json = jsonDecode(body);
      return json['id'] as String;
    } finally {
      client.close();
    }
  }

  // ═══════════════════════════════════════════
  // Credenciales — archivo local (por dispositivo)
  // ═══════════════════════════════════════════

  static Future<File> _archivoLocal() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(
        '${dir.path}${Platform.pathSeparator}agenda_nube.json');
  }

  static Future<({String? token, String? gistId})>
      leerCredenciales() async {
    try {
      final f = await _archivoLocal();
      if (!await f.exists()) return (token: null, gistId: null);
      final json = jsonDecode(await f.readAsString());
      return (
        token: json['token'] as String?,
        gistId: json['gistId'] as String?,
      );
    } catch (_) {
      return (token: null, gistId: null);
    }
  }

  static Future<void> guardarCredenciales(
      {required String token, required String gistId}) async {
    final f = await _archivoLocal();
    await f
        .writeAsString(jsonEncode({'token': token, 'gistId': gistId}));
  }

  static Future<void> borrarCredenciales() async {
    final f = await _archivoLocal();
    if (await f.exists()) await f.delete();
  }
}
