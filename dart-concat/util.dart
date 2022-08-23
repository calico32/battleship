/// Basically https://github.com/frencojobs/tint/blob/main/lib/tint.dart.
import 'dart:math';

/// Formats a string if ansi escape sequences are supported.
String Function(String) format(dynamic start, dynamic end) =>
    (x) => '\x1B[${start}m$x\x1B[${end}m';

/// Converts an rgb value of given [r], [g] and [b] int values
/// to an ANSI usable color.
int rgbToAnsiCode(int r, int g, int b) =>
    (((r.clamp(0, 255) / 255) * 5).toInt() * 36 +
            ((g.clamp(0, 255) / 255) * 5).toInt() * 6 +
            ((b.clamp(0, 255) / 255) * 5).toInt() +
            16)
        .clamp(0, 256)
        .toInt();

/// Regular Expression pattern for all possible types of ANSI escape
/// sequences in a [String].
final ansiPattern = RegExp([
  '[\\u001B\\u009B][[\\]()#;?]*(?:(?:(?:[a-zA-Z\\d]*(?:;[-a-zA-Z\\d\\/#&.:=?%@~_]*)*)?\\u0007)',
  '(?:(?:\\d{1,4}(?:;\\d{0,4})*)?[\\dA-PR-TZcf-ntqry=><~]))'
].join('|'));

enum Colors {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  brightBlack,
  brightRed,
  brightGreen,
  brightYellow,
  brightBlue,
  brightMagenta,
  brightCyan,
  brightWhite,
  // aliases
  gray,
  grey,
}

enum Style {
  bold,
  dim,
  italic,
  underline,
  blink,
  reverse,
  hidden,
  strikethrough
}

extension TintCommon on String {
  String fg(Colors? color) {
    if (color == null) return reset();
    if (color.index < 8) return format(color.index + 30, 39)(this);
    if (color.index < 16) return format(color.index + 82, 39)(this);
    return format(Colors.brightBlack.index + 82, 39)(this);
  }

  String bg(Colors? color) {
    if (color == null) return reset();
    if (color.index < 8) return format(color.index + 40, 49)(this);
    if (color.index < 16) return format(color.index + 92, 49)(this);
    return format(Colors.brightBlack.index + 92, 39)(this);
  }

  String style(Style style) =>
      format(style.index + 1, max(22, style.index + 20))(this);

  String styles(List<Style> styles) => styles.fold(this, (a, b) => style(b));

  // snippet below taken from tint source
  // https://github.com/frencojobs/tint/blob/main/lib/tint.dart

  String strip() => replaceAll(ansiPattern, '');
  String reset() => format(0, 0)(this);

  // foreground colors
  String black() => format(30, 39)(this);
  String red() => format(31, 39)(this);
  String green() => format(32, 39)(this);
  String yellow() => format(33, 39)(this);
  String blue() => format(34, 39)(this);
  String magenta() => format(35, 39)(this);
  String cyan() => format(36, 39)(this);
  String white() => format(37, 39)(this);
  String brightBlack() => format(90, 39)(this);
  String brightRed() => format(91, 39)(this);
  String brightGreen() => format(92, 39)(this);
  String brightYellow() => format(93, 39)(this);
  String brightBlue() => format(94, 39)(this);
  String brightMagenta() => format(95, 39)(this);
  String brightCyan() => format(96, 39)(this);
  String brightWhite() => format(97, 39)(this);

  // background colors
  String onBlack() => format(40, 49)(this);
  String onRed() => format(41, 49)(this);
  String onGreen() => format(42, 49)(this);
  String onYellow() => format(43, 49)(this);
  String onBlue() => format(44, 49)(this);
  String onMagenta() => format(45, 49)(this);
  String onCyan() => format(46, 49)(this);
  String onWhite() => format(47, 49)(this);
  String onBrightBlack() => format(100, 49)(this);
  String onBrightRed() => format(101, 49)(this);
  String onBrightGreen() => format(102, 49)(this);
  String onBrightYellow() => format(103, 49)(this);
  String onBrightBlue() => format(104, 49)(this);
  String onBrightMagenta() => format(105, 49)(this);
  String onBrightCyan() => format(106, 49)(this);
  String onBrightWhite() => format(107, 49)(this);

  // attributes
  String bold() => format(1, 22)(this);
  String dim() => format(2, 22)(this);
  String italic() => format(3, 23)(this);
  String underline() => format(4, 24)(this);
  String blink() => format(5, 25)(this);
  String inverse() => format(7, 27)(this);
  String hidden() => format(8, 28)(this);
  String strikethrough() => format(9, 29)(this);

  // aliases
  String gray() => brightBlack();
  String grey() => brightBlack();
  String onGray() => onBrightBlack();
  String onGrey() => onBrightBlack();

  // end of snippet from tint source
}
