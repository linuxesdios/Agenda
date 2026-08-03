import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Servicio de encriptación AES-256-GCM con derivación de clave desde
/// contraseña maestra usando PBKDF2.
///
/// Equivale al sistema de contraseñas de la app web que usa
/// Web Crypto API (PBKDF2 + AES-GCM).
class ServicioCripto {
  static final _aes = AesGcm.with256bits();
  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  // Salt fijo — igual que en la app web para compatibilidad
  static final _salt = Uint8List.fromList(
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

  /// Deriva una clave AES-256 a partir de la contraseña maestra.
  static Future<SecretKey> _derivarClave(String password) async {
    final claveInicial = SecretKey(utf8.encode(password));
    return _pbkdf2.deriveKey(
      secretKey: claveInicial,
      nonce: _salt,
    );
  }

  /// Encripta texto plano con la contraseña maestra.
  /// Devuelve base64(IV + ciphertext + tag).
  static Future<String> encriptar(String texto, String password) async {
    final clave = await _derivarClave(password);
    final secretBox = await _aes.encrypt(
      utf8.encode(texto),
      secretKey: clave,
    );
    // Combinar nonce (12 bytes) + ciphertext + MAC (16 bytes)
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return base64Encode(combined);
  }

  /// Desencripta texto cifrado con la contraseña maestra.
  /// Lanza excepción si la contraseña es incorrecta.
  static Future<String> desencriptar(
      String textoCifrado, String password) async {
    final clave = await _derivarClave(password);
    final combined = base64Decode(textoCifrado);

    final nonce = combined.sublist(0, 12);
    final cipherText = combined.sublist(12, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final descifrado = await _aes.decrypt(secretBox, secretKey: clave);
    return utf8.decode(descifrado);
  }

  /// Verifica si una contraseña maestra es válida intentando desencriptar
  /// un texto de prueba.
  static Future<bool> verificarPassword(
      String textoCifrado, String password) async {
    try {
      await desencriptar(textoCifrado, password);
      return true;
    } catch (_) {
      return false;
    }
  }
}
