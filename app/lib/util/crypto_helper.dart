import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 加密帮助类
///
/// 用于加密和解密敏感数据（如密码）
/// 使用 AES 加密算法，密钥存储在 FlutterSecureStorage 中
class CryptoHelper {
  static const String _encryptionKeyKey = 'linkdrop_encryption_key';
  static const String _ivKey = 'linkdrop_encryption_iv';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 单例模式
  static final CryptoHelper _instance = CryptoHelper._internal();
  factory CryptoHelper() => _instance;
  CryptoHelper._internal();

  /// 获取或生成加密密钥
  Future<encrypt.Key> _getKey() async {
    String? keyString = await _storage.read(key: _encryptionKeyKey);

    if (keyString == null) {
      // 生成新的随机密钥
      final random = Random.secure();
      final keyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      keyString = base64Encode(keyBytes);
      await _storage.write(key: _encryptionKeyKey, value: keyString);
    }

    return encrypt.Key.fromBase64(keyString);
  }

  /// 获取或生成 IV（初始化向量）
  Future<encrypt.IV> _getIV() async {
    String? ivString = await _storage.read(key: _ivKey);

    if (ivString == null) {
      // 生成新的随机 IV
      final random = Random.secure();
      final ivBytes = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        ivBytes[i] = random.nextInt(256);
      }
      ivString = base64Encode(ivBytes);
      await _storage.write(key: _ivKey, value: ivString);
    }

    return encrypt.IV.fromBase64(ivString);
  }

  /// 加密文本
  ///
  /// [plainText] 明文
  /// 返回加密后的 Base64 字符串
  Future<String?> encryptText(String plainText) async {
    try {
      final key = await _getKey();
      final iv = await _getIV();

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('加密失败: $e');
      return null;
    }
  }

  /// 解密文本
  ///
  /// [encryptedText] 加密后的 Base64 字符串
  /// 返回明文
  Future<String?> decryptText(String encryptedText) async {
    try {
      final key = await _getKey();
      final iv = await _getIV();

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      debugPrint('解密失败: $e');
      return null;
    }
  }

  /// 生成数据的哈希值（用于校验）
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
