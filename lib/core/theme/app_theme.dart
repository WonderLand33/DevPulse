import 'package:flutter/material.dart';

/// 全局设计 token：间距、圆角、动效时长。
/// 统一从这里取值，保证各模块视觉一致。
class Dims {
  Dims._();
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gap = 12;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 32;

  static const double radiusSm = 6;
  static const double radius = 10;
  static const double radiusLg = 14;

  static const double sidebarMin = 200;
  static const double sidebarMax = 380;
  static const double sidebarDefault = 258;

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
}

/// 等宽字体回退链——不打包字体文件，直接复用系统等宽字体，
/// 保证 100% 离线且体积最小。Windows: Consolas / Cascadia，macOS: Menlo。
const List<String> kMonoFontFallback = <String>[
  'Consolas',
  'Cascadia Code',
  'Cascadia Mono',
  'Menlo',
  'SF Mono',
  'DejaVu Sans Mono',
  'monospace',
];

/// 用户在设置里选择的等宽字体族（null=用系统回退链）。
/// 由 DevPulseApp 构建时从 provider 同步，供 [PaletteX.mono] 读取。
String? kUserMonoFamily;

/// 设置里可选的等宽字体（跨平台，未安装自动回退）。
const List<String> kMonoFontChoices = [
  'Consolas',
  'Cascadia Code',
  'Cascadia Mono',
  'JetBrains Mono',
  'Fira Code',
  'Source Code Pro',
  'Menlo',
  'SF Mono',
];

/// 设置里可选的界面字体。
const List<String> kUiFontChoices = [
  'Microsoft YaHei',
  'Segoe UI',
  'PingFang SC',
  'Noto Sans SC',
  'Inter',
  'Source Han Sans SC',
];

/// 语义化配色。暗色对标 VS Code Dark+，浅色为配套明亮方案。
class AppPalette {
  final Color background; // 应用最底层
  final Color surface; // 面板/卡片
  final Color surfaceAlt; // 侧栏等次级面板
  final Color border;
  final Color accent; // 主强调色
  final Color accentSoft; // 强调色低透明填充
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  static const AppPalette dark = AppPalette(
    background: Color(0xFF1B1D23),
    surface: Color(0xFF23262E),
    surfaceAlt: Color(0xFF1E2127),
    border: Color(0xFF31353F),
    accent: Color(0xFF4C8DFF),
    accentSoft: Color(0x224C8DFF),
    textPrimary: Color(0xFFE6E8EC),
    textSecondary: Color(0xFF9BA1AD),
    success: Color(0xFF3FB950),
    warning: Color(0xFFE3B341),
    danger: Color(0xFFF85149),
    info: Color(0xFF58A6FF),
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDEFF3),
    border: Color(0xFFDDE1E8),
    accent: Color(0xFF2F6FEB),
    accentSoft: Color(0x152F6FEB),
    textPrimary: Color(0xFF1B1F27),
    textSecondary: Color(0xFF616B7A),
    success: Color(0xFF1A7F37),
    warning: Color(0xFFB7791F),
    danger: Color(0xFFD1242F),
    info: Color(0xFF1F6FEB),
  );
}

/// 通过 ThemeExtension 把 AppPalette 挂到 ThemeData 上，
/// 组件里用 `context.palette` 取色。
class AppThemeExt extends ThemeExtension<AppThemeExt> {
  final AppPalette palette;
  const AppThemeExt(this.palette);

  @override
  ThemeExtension<AppThemeExt> copyWith({AppPalette? palette}) =>
      AppThemeExt(palette ?? this.palette);

  @override
  ThemeExtension<AppThemeExt> lerp(
      covariant ThemeExtension<AppThemeExt>? other, double t) {
    return this; // 主题切换为离散切换，无需插值
  }
}

extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppThemeExt>()!.palette;

  /// 便捷取等宽 TextStyle。
  TextStyle mono({double size = 13, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: kUserMonoFamily,
        fontFamilyFallback: kMonoFontFallback,
        fontSize: size,
        height: 1.5,
        color: color ?? palette.textPrimary,
        fontWeight: weight,
      );
}

ThemeData buildAppTheme(AppPalette p, Brightness brightness, {String? uiFont}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
  ).copyWith(
    surface: p.surface,
    primary: p.accent,
    error: p.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: uiFont,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    dividerColor: p.border,
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.compact,
    extensions: [AppThemeExt(p)],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radiusSm),
      ),
      textStyle: TextStyle(color: p.textPrimary, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: p.surfaceAlt,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Dims.gap, vertical: 10),
      hintStyle: TextStyle(color: p.textSecondary, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dims.radiusSm),
        borderSide: BorderSide(color: p.accent, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(horizontal: Dims.gapMd, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.border),
        padding:
            const EdgeInsets.symmetric(horizontal: Dims.gapMd, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dims.radiusSm),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? p.accentSoft
                : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? p.accent
                : p.textSecondary),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.border),
        borderRadius: BorderRadius.circular(Dims.radius),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(4),
      thumbColor: WidgetStatePropertyAll(p.border),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
  );
}
