import 'dart:typed_data';

import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MarkdownLogic {
  static String toHtml(String source) {
    final body = md.markdownToHtml(
      source,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    return '''<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DevPulse Markdown 导出</title>
<style>
  body { font-family: -apple-system, "Segoe UI", "Microsoft YaHei", sans-serif;
         max-width: 820px; margin: 40px auto; padding: 0 20px; line-height: 1.7;
         color: #24292f; }
  h1,h2 { border-bottom: 1px solid #d0d7de; padding-bottom: .3em; }
  code { background: #eff1f3; padding: .2em .4em; border-radius: 6px;
         font-family: Consolas, Menlo, monospace; font-size: 90%; }
  pre { background: #f6f8fa; padding: 16px; border-radius: 8px; overflow: auto; }
  pre code { background: none; padding: 0; }
  blockquote { border-left: 4px solid #d0d7de; margin: 0; padding: 0 1em;
               color: #57606a; }
  table { border-collapse: collapse; }
  th,td { border: 1px solid #d0d7de; padding: 6px 13px; }
  img { max-width: 100%; }
  a { color: #0969da; }
</style>
</head>
<body>
$body
</body>
</html>''';
  }

  /// 生成 PDF 字节。cjkFont 提供时可正确渲染中文。
  static Future<Uint8List> toPdf(String source, {pw.Font? cjkFont}) async {
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
    ).parse(source);

    final doc = pw.Document();
    final base = cjkFont;
    final theme = base != null
        ? pw.ThemeData.withFont(base: base, bold: base, italic: base)
        : pw.ThemeData.base();

    final widgets = <pw.Widget>[];
    for (final node in nodes) {
      widgets.addAll(_renderNode(node));
    }

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => widgets,
      ),
    );
    return doc.save();
  }

  static List<pw.Widget> _renderNode(md.Node node) {
    if (node is md.Text) {
      final t = node.text.trim();
      return t.isEmpty ? [] : [pw.Paragraph(text: t)];
    }
    if (node is! md.Element) return [];

    final text = node.textContent.trim();
    switch (node.tag) {
      case 'h1':
        return [_heading(text, 24)];
      case 'h2':
        return [_heading(text, 20)];
      case 'h3':
        return [_heading(text, 17)];
      case 'h4':
      case 'h5':
      case 'h6':
        return [_heading(text, 14)];
      case 'p':
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
          )
        ];
      case 'pre':
        return [
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F8FA)),
            child: pw.Text(text,
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
          )
        ];
      case 'blockquote':
        return [
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8, left: 4),
            padding: const pw.EdgeInsets.only(left: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  left: pw.BorderSide(color: PdfColor.fromInt(0xFFD0D7DE), width: 3)),
            ),
            child: pw.Text(text,
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColor.fromInt(0xFF57606A))),
          )
        ];
      case 'ul':
      case 'ol':
        final items = <pw.Widget>[];
        final children = node.children ?? [];
        var idx = 1;
        for (final li in children) {
          if (li is md.Element && li.tag == 'li') {
            final marker = node.tag == 'ol' ? '${idx++}. ' : '•  ';
            items.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(marker, style: const pw.TextStyle(fontSize: 11)),
                  pw.Expanded(
                      child: pw.Text(li.textContent.trim(),
                          style: const pw.TextStyle(fontSize: 11))),
                ],
              ),
            ));
          }
        }
        return [
          pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: items))
        ];
      case 'hr':
        return [pw.Divider(color: const PdfColor.fromInt(0xFFD0D7DE))];
      default:
        return text.isEmpty ? [] : [pw.Paragraph(text: text)];
    }
  }

  static pw.Widget _heading(String text, double size) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 8),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold)),
      );
}
