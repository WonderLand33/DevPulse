import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/kv_store.dart';
import '../../core/storage/secure_store.dart';
import 'totp_logic.dart';

/// TOTP 账号元数据（不含种子；种子在系统级加密存储中）。
class TotpAccount {
  final String id;
  final String label;
  final String issuer;
  final int digits;
  final int period;
  final String algorithm;
  final int sortIndex;

  const TotpAccount({
    required this.id,
    required this.label,
    required this.issuer,
    required this.digits,
    required this.period,
    required this.algorithm,
    required this.sortIndex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'issuer': issuer,
        'digits': digits,
        'period': period,
        'algorithm': algorithm,
        'sortIndex': sortIndex,
      };

  static TotpAccount fromMap(Map m) => TotpAccount(
        id: m['id'] as String,
        label: m['label'] as String? ?? '未命名',
        issuer: m['issuer'] as String? ?? '',
        digits: m['digits'] as int? ?? 6,
        period: m['period'] as int? ?? 30,
        algorithm: m['algorithm'] as String? ?? 'SHA1',
        sortIndex: m['sortIndex'] as int? ?? 0,
      );
}

class TotpState {
  final List<TotpAccount> accounts;

  /// 已加载种子的账号 id → 种子。
  final Map<String, String> secrets;
  const TotpState(this.accounts, this.secrets);
}

class TotpController extends Notifier<TotpState> {
  dynamic get _box => KvStore.instance.totp;

  @override
  TotpState build() {
    final accounts = _loadMeta();
    // 异步加载种子后刷新。
    _loadSecrets(accounts);
    return TotpState(accounts, const {});
  }

  List<TotpAccount> _loadMeta() {
    final items = <TotpAccount>[];
    for (final e in _box.values) {
      items.add(TotpAccount.fromMap(e as Map));
    }
    items.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return items;
  }

  Future<void> _loadSecrets(List<TotpAccount> accounts) async {
    final map = <String, String>{};
    for (final a in accounts) {
      final s = await SecureStore.instance.readTotpSecret(a.id);
      if (s != null) map[a.id] = s;
    }
    state = TotpState(accounts, map);
  }

  Future<void> addFromConfig(TotpConfig c) async {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}';
    final account = TotpAccount(
      id: id,
      label: c.label,
      issuer: c.issuer,
      digits: c.digits,
      period: c.period,
      algorithm: c.algorithm,
      sortIndex: state.accounts.length,
    );
    await SecureStore.instance.writeTotpSecret(id, c.secret);
    await _box.put(id, account.toMap());
    final accounts = _loadMeta();
    final secrets = Map<String, String>.from(state.secrets)..[id] = c.secret;
    state = TotpState(accounts, secrets);
  }

  Future<void> remove(String id) async {
    await SecureStore.instance.deleteTotpSecret(id);
    await _box.delete(id);
    final accounts = _loadMeta();
    final secrets = Map<String, String>.from(state.secrets)..remove(id);
    state = TotpState(accounts, secrets);
  }

  Future<void> rename(String id, String label, String issuer) async {
    final a = state.accounts.firstWhere((e) => e.id == id);
    final updated = TotpAccount(
      id: a.id,
      label: label,
      issuer: issuer,
      digits: a.digits,
      period: a.period,
      algorithm: a.algorithm,
      sortIndex: a.sortIndex,
    );
    await _box.put(id, updated.toMap());
    state = TotpState(_loadMeta(), state.secrets);
  }
}

final totpProvider =
    NotifierProvider<TotpController, TotpState>(TotpController.new);
