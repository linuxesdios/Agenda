import 'tarea.dart'; // para generarId()

/// Contraseña encriptada.
/// El campo [valorEncriptado] contiene los datos cifrados con AES-256-GCM.
/// Solo se puede descifrar con la contraseña maestra del usuario.
class Contrasena {
  String id;
  String nombre; // nombre descriptivo (ej: "Gmail", "Banco")
  String valorEncriptado; // base64(IV + ciphertext + tag)

  Contrasena({
    String? id,
    required this.nombre,
    required this.valorEncriptado,
  }) : id = id ?? generarId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'valorEncriptado': valorEncriptado,
      };

  factory Contrasena.fromJson(Map<String, dynamic> json) => Contrasena(
        id: json['id'] as String? ?? generarId(),
        nombre: json['nombre'] as String? ?? '',
        valorEncriptado: json['valorEncriptado'] as String? ?? '',
      );
}
