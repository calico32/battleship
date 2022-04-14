import 'dart:io';
import 'dart:math';

// tint, ANSI coloring helpers, by Frenco Jobs (https://github.com/frencojobs)
// used in accordance with the MIT license
// https://pub.dev/packages/tint
// https://github.com/frencojobs/tint
import 'package:tint/src/helpers.dart';

import 'constants.dart';

final idAlphabet = alphabet + alphabet.toLowerCase() + numbers;

String generateId() {
  var rng = Random();
  var id = "";
  for (var i = 0; i < 4; i++) {
    id += idAlphabet[rng.nextInt(idAlphabet.length)];
  }
  return id;
}

int ord(String key) {
  return int.parse(key.codeUnits.map((e) => e.toString()).join());
}

void hideCursor() {
  stdout.write("\x1b[?25l");
}

void showCursor() {
  stdout.write("\x1b[?25h");
}

void moveCursor(int x, int y) {
  stdout.write("\x1b[$y;${x}H");
}

void clearScreen() {
  stdout.write("\x1B[2J");
  moveCursor(0, 0);
}

extension ListCompare on List {
  bool equals(List other) {
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}

String formatMenu(List<String> options, int selected) {
  String result = "";
  for (int i = 0; i < options.length; i++) {
    if (i == selected) {
      result += "> ";
    } else {
      result += "  ";
    }
    result += options[i];
    result += "\n";
  }
  return result;
}

bool handleMenuNav(Map<String, dynamic> data, String key, int numItems) {
  if (key == arrowUp) {
    data["selected"] = max(0, (data["selected"] as int) - 1);
    return true;
  }

  if (key == arrowDown) {
    data["selected"] = min(numItems - 1, (data["selected"] as int) + 1);
    return true;
  }

  return false;
}

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
