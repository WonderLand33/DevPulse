import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 系统级加密存储封装。
///
/// 用于 TOTP 种子密钥等最高敏感数据：
///  - Windows → Credential Manager
///  - macOS   → Keychain
/// 绝不写入普通文件，绝不网络备份。
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _prefix = 'totp_secret_';

  final _storage = const FlutterSecureStorage(
    wOptions: WindowsOptions(),
  );

  Future<void> writeTotpSecret(String accountId, String base32Secret) =>
      _storage.write(key: '$_prefix$accountId', value: base32Secret);

  Future<String?> readTotpSecret(String accountId) =>
      _storage.read(key: '$_prefix$accountId');

  Future<void> deleteTotpSecret(String accountId) =>
      _storage.delete(key: '$_prefix$accountId');
}
