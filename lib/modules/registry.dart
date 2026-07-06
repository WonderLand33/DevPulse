import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'module.dart';

// 各模块页面。
import 'json_tool/json_page.dart';
import 'unix_time/unix_time_page.dart';
import 'base64_tool/base64_page.dart';
import 'jwt_tool/jwt_page.dart';
import 'password_gen/password_page.dart';
import 'cron_tool/cron_page.dart';
import 'diff_tool/diff_page.dart';
import 'x509_tool/x509_page.dart';
import 'crypto_tool/crypto_page.dart';
import 'markdown_tool/markdown_page.dart';
import 'qr_tool/qr_page.dart';
import 'todo_tool/todo_page.dart';
import 'totp_tool/totp_page.dart';
import 'notes_tool/note_page.dart';
import 'settings/settings_page.dart';

/// 全部工具模块注册表——单一数据源，被侧栏与命令面板共享。
final List<ToolModule> kModules = [
  ToolModule(
    id: 'json',
    title: 'JSON 处理器',
    subtitle: '格式化 / 压缩 / 转义 · 折叠 · 搜索',
    icon: Icons.data_object,
    group: '编码 & 数据',
    keywords: ['json', 'format', 'beautify', 'minify', '压缩', '美化', '转义'],
    builder: (_) => const JsonPage(),
  ),
  ToolModule(
    id: 'base64',
    title: 'Base64 工具箱',
    subtitle: '文本 / 图片 ↔ Base64，DataURL',
    icon: Icons.transform,
    group: '编码 & 数据',
    keywords: ['base64', 'b64', 'dataurl', '图片', 'encode', 'decode', '编码'],
    builder: (_) => const Base64Page(),
  ),
  ToolModule(
    id: 'jwt',
    title: 'JWT 调试器',
    subtitle: '三段解析 / 过期告警 / 本地验签',
    icon: Icons.vpn_key_outlined,
    group: '编码 & 数据',
    keywords: ['jwt', 'token', 'jws', '令牌', 'header', 'payload'],
    builder: (_) => const JwtPage(),
  ),
  ToolModule(
    id: 'x509',
    title: 'X.509 证书解码',
    subtitle: 'PEM 解析 / 有效期告警',
    icon: Icons.verified_user_outlined,
    group: '编码 & 数据',
    keywords: ['x509', 'cert', 'certificate', 'pem', '证书', 'ssl', 'tls'],
    builder: (_) => const X509Page(),
  ),
  ToolModule(
    id: 'diff',
    title: '文本对比 Diff',
    subtitle: '双栏 / 合并 · 行内字符差异',
    icon: Icons.difference_outlined,
    group: '文本 & 文档',
    keywords: ['diff', 'compare', '对比', '差异', 'merge'],
    builder: (_) => const DiffPage(),
  ),
  ToolModule(
    id: 'markdown',
    title: 'Markdown 渲染',
    subtitle: '实时预览 · 导出 HTML / PDF',
    icon: Icons.article_outlined,
    group: '文本 & 文档',
    keywords: ['markdown', 'md', 'gfm', '渲染', 'html', 'pdf'],
    builder: (_) => const MarkdownPage(),
  ),
  ToolModule(
    id: 'qr',
    title: 'QR 二维码工具',
    subtitle: '生成 / 解码 · 自定义样式',
    icon: Icons.qr_code_2,
    group: '文本 & 文档',
    keywords: ['qr', 'qrcode', '二维码', 'scan', '生成', '识别'],
    builder: (_) => const QrPage(),
  ),
  ToolModule(
    id: 'unixtime',
    title: 'Unix 时间转换',
    subtitle: '时间戳 ↔ 可读 · 多维展示',
    icon: Icons.schedule,
    group: '时间',
    keywords: ['unix', 'time', 'timestamp', '时间戳', 'epoch', 'date', '时间'],
    builder: (_) => const UnixTimePage(),
  ),
  ToolModule(
    id: 'cron',
    title: 'Cron 表达式',
    subtitle: '自然语言解析 · 预测执行时间',
    icon: Icons.timer_outlined,
    group: '时间',
    keywords: ['cron', 'crontab', 'schedule', '定时', '计划任务'],
    builder: (_) => const CronPage(),
  ),
  ToolModule(
    id: 'crypto',
    title: '加密工具',
    subtitle: 'SHA 哈希 · AES 对称 · RSA 非对称',
    icon: Icons.enhanced_encryption_outlined,
    group: '安全 & 效率',
    keywords: [
      'crypto', 'encrypt', 'hash', 'aes', 'rsa', 'sha', 'md5',
      '加密', '解密', '哈希', '散列', '签名', '密钥'
    ],
    builder: (_) => const CryptoPage(),
  ),
  ToolModule(
    id: 'password',
    title: '密码生成器',
    subtitle: '安全随机 · 信息熵强度',
    icon: Icons.password,
    group: '安全 & 效率',
    keywords: ['password', 'pwd', '密码', 'random', '生成', '强度'],
    builder: (_) => const PasswordPage(),
  ),
  ToolModule(
    id: 'totp',
    title: 'TOTP 认证令牌',
    subtitle: '桌面版验证器 · 加密存储',
    icon: Icons.security,
    group: '安全 & 效率',
    keywords: ['totp', 'otp', '2fa', 'mfa', 'authenticator', '验证码', '令牌'],
    builder: (_) => const TotpPage(),
  ),
  ToolModule(
    id: 'todo',
    title: 'TODO LIST',
    subtitle: '轻量任务清单 · 本地持久化',
    icon: Icons.checklist_rtl,
    group: '安全 & 效率',
    keywords: ['todo', 'list', 'task', '任务', '待办', '便签', '清单'],
    builder: (_) => const TodoPage(),
  ),
  ToolModule(
    id: 'notes',
    title: '备忘快贴',
    subtitle: '灵感与代码片段的即时暂存区',
    icon: Icons.bolt,
    group: '安全 & 效率',
    keywords: ['note', 'notes', 'scratch', '备忘', '快贴', '便签', '片段', 'snippet'],
    builder: (_) => const NotePage(),
  ),
  ToolModule(
    id: 'settings',
    title: '设置',
    subtitle: '主题 / 字体 / 关于',
    icon: Icons.tune,
    group: '系统',
    keywords: ['settings', '设置', 'theme', '主题', 'about', '关于', 'font', '字体'],
    builder: (_) => const SettingsPage(),
  ),
];

ToolModule moduleById(String id) =>
    kModules.firstWhere((m) => m.id == id, orElse: () => kModules.first);

/// 当前选中模块 id。
class SelectedModule extends Notifier<String> {
  @override
  String build() => 'json';

  void select(String id) => state = id;
}

final selectedModuleProvider =
    NotifierProvider<SelectedModule, String>(SelectedModule.new);
