// const _whitespace = "\t\n\x0b\x0c\r ";

// class TextWrapper {
//   int width;
//   String initialIndent;
//   String subsequentIndent;
//   bool expandTabs;
//   int tabSize;
//   bool replaceWhitespace;
//   bool fixSentenceEndings;
//   bool breakLongWords;
//   bool breakOnHyphens;
//   bool dropWhitespace;
//   int? maxLines;
//   String placeholder;

//   Map<int, int> unicodeWhitespaceTrans = {};
//   int uspace = " ".codeUnitAt(0);
//   String wordPunct = "[\\w!\"'&.,?]";
//   String letter = r"[^\d\W]";
//   String whitespace = "[${RegExp.escape(_whitespace)}]";
//   String noWhitespace = "[^${RegExp.escape(_whitespace)}]";
//   late RegExp wordSep;
//   late RegExp wordSepSimple;
//   RegExp sentenceEnd = RegExp(
//     r"[a-z]" // lowercase letter
//     r"[\.\!\?]" // sentence ending punct.
//     "[\"']?" // optional end-of-quote
//     r"\Z",
//   );

//   TextWrapper({
//     this.width = 70,
//     this.initialIndent = "",
//     this.subsequentIndent = "",
//     this.expandTabs = true,
//     this.tabSize = 8,
//     this.replaceWhitespace = true,
//     this.fixSentenceEndings = false,
//     this.breakLongWords = true,
//     this.breakOnHyphens = true,
//     this.dropWhitespace = true,
//     this.maxLines,
//     this.placeholder = " [...]",
//   }) {
//     for (var i = 0; i < _whitespace.length; i++) {
//       var ch = _whitespace[i];
//       unicodeWhitespaceTrans[ch.codeUnitAt(0)] = uspace;
//     }

//     var ws = whitespace;
//     var wp = wordPunct;
//     var nws = noWhitespace;
//     var lt = letter;

//     wordSep = RegExp(
//       "("
//       "${ws}s+|"
//       "(?<=${wp}s) -{2,} (?=\\w)|"
//       "${nws}s+? (?:"
//       "-(?: (?<=${lt}s{2}-) | (?<=${lt}s-${lt}s-))(?= ${lt}s -? ${lt}s)|"
//       "(?=%(ws)s|\\Z)|"
//       "(?<=%(wp)s) (?=-{2,}\\w)"
//       "))",
//     );

//     wordSepSimple = RegExp("($whitespace+)");
//   }

//   String _mungeWhitespace(String text) {
//     if (expandTabs) {
//       text = _expandTabs(text, tabSize);
//     }
//     if (replaceWhitespace) {
//       text = _translate(text, unicodeWhitespaceTrans);
//     }
//     return text;
//   }

//   List<String> _split(String text) {
//     var chunks = text.split(breakOnHyphens ? wordSep : wordSepSimple);
//     return chunks.where((ch) => ch.isNotEmpty).toList();
//   }

//   void _fixSentenceEndings(List<String> chunks) {
//     var i = 0;
//     while (i < chunks.length - 1) {
//       if (chunks[i + 1] == " " && sentenceEnd.hasMatch(chunks[i])) {
//         chunks[i + 1] = "  ";
//         i += 2;
//       } else {
//         i += 1;
//       }
//     }
//   }

//   void _handleLongWord(
//     List<String> reversedChunks,
//     List<String> currentLine,
//     int currentLength,
//     int width,
//   ) {
//     var spaceLeft = width - currentLength;
//     if (width < 1) {
//       spaceLeft = 1;
//     }

//     if (breakLongWords) {
//       var end = spaceLeft;
//       var chunk = reversedChunks.last;
//       if (breakOnHyphens && chunk.length > spaceLeft) {
//         var hyphen = chunk.substring(0, spaceLeft).lastIndexOf("-");
//         if (hyphen > 0 && chunk.runes.any((r) => r != "-".codeUnitAt(0))) {
//           end = hyphen + 1;
//         }
//       }
//       currentLine.add(chunk.substring(0, end));
//       reversedChunks.last = chunk.isEmpty ? "" : chunk.substring(end + 1);
//     } else if (currentLine.isEmpty) {
//       currentLine.add(reversedChunks.removeLast());
//     }
//   }

//   List<String> _wrapChunks(List<String> chunks) {
//     var lines = <String>[];
//     if (width <= 0) {
//       throw ArgumentError.value(width, "width");
//     }
//     if (maxLines != null) {
//       String indent;

//       if (maxLines! > 1) {
//         indent = subsequentIndent;
//       } else {
//         indent = initialIndent;
//       }
//       if (indent.length + placeholder.trimLeft().length > width) {
//         throw ArgumentError("placeholder too large for max width");
//       }
//     }

//     chunks = chunks.reversed.toList();

//     while (chunks.isNotEmpty) {
//       var currentLine = <String>[];
//       var currentLength = 0;

//       String indent;
//       if (lines.isNotEmpty) {
//         indent = subsequentIndent;
//       } else {
//         indent = initialIndent;
//       }

//       var width = this.width - indent.length;

//       if (dropWhitespace && chunks.last.trim() == "" && lines.isNotEmpty) {
//         chunks.removeLast();
//       }

//       while (chunks.isNotEmpty) {
//         var l = chunks.last.length;

//         if (currentLength + l <= width) {
//           currentLine.add(chunks.removeLast());
//           currentLength += l;
//         } else {
//           break;
//         }
//       }

//       if (chunks.isNotEmpty && chunks.last.length > width) {
//         _handleLongWord(chunks, currentLine, currentLength, width);
//         currentLength = currentLine
//             .map((e) => e.length)
//             .reduce((value, element) => value + element);
//       }

//       if (dropWhitespace &&
//           currentLine.isNotEmpty &&
//           currentLine.last.trim() == "") {
//         currentLength -= currentLine.last.length;
//         currentLine.removeLast();
//       }

//       if (currentLine.isNotEmpty) {}
//     }

//     return lines;
//   }
// }

// String _expandTabs(String text, [int tabSize = 8]) {
//   var result = "";
//   var resultLength = 0;

//   for (var curr = 0; curr < text.length; curr++) {
//     if (text[curr] == '\t') {
//       if (tabSize > 0) {
//         var size = tabSize - (resultLength % tabSize);
//         resultLength += size;
//         result += " " * size;
//       }
//     } else {
//       resultLength++;
//       result += text[curr];
//       if (text[curr] == '\n' || text[curr] == '\r') {
//         resultLength = 0;
//       }
//     }
//   }

//   return result;
// }

// String _translate(String text, Map<int, int> dictionary) {
//   var chars = List<int>.from(text.codeUnits);
//   for (var i = 0; i < chars.length; i++) {
//     var replacement = dictionary[chars[i]];
//     if (replacement != null) {
//       chars[i] = replacement;
//     }
//   }
//   return String.fromCharCodes(chars);
// }
