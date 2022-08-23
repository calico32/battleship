/// Quick utility for concatenating a lot of dart files. Used to concatenate the
/// battleship program for submission to CollegeBoard (only one file allowed per
/// submission). It does not handle a lot of edge cases when it comes to imports
/// and comments, so use with caution.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'util.dart';

class Import {
  String content;
  final String specifier;
  List<String> comments;

  Import(this.content, this.specifier, [List<String>? comments])
      : comments = comments ?? [];

  @override
  String toString() =>
      comments.isNotEmpty ? "${comments.join('\n')}\n$content" : content;
}

class Source {
  List<Import> imports;
  List<String> source;

  Source(this.imports, this.source);

  @override
  String toString() {
    var sortedImports = imports.toList()
      ..sort((a, b) => a.specifier.compareTo(b.specifier));

    var output = "";

    var stdlibCommentAdded = false;
    var lastPackage = "";
    for (var import in sortedImports) {
      // weird comment system for stdlib imports because collegeboard
      // attribution
      if (!stdlibCommentAdded && import.specifier.startsWith("dart:")) {
        import.comments.add("// dart standard library");
        stdlibCommentAdded = true;
        lastPackage = import.specifier;
      } else if (!import.specifier.startsWith("dart:") &&
          lastPackage != import.specifier.split("/").first) {
        output += "\n\n";
        lastPackage = import.specifier;
      }

      output += import.toString();
      output += "\n";
    }

    output += "\n\n" + source.join("\n");
    output = output.replaceAll(RegExp(r"\n\n\n+"), "\n\n");
    return output;
  }
}

Future<Source> concatDartSource(
  File entrypoint, [
  Set<String>? alreadyImported,
  Set<String>? alreadyConcatenated,
  int depth = 0,
  String? basePath,
]) async {
  alreadyImported ??= {};
  alreadyConcatenated ??= {};
  basePath ??= entrypoint.parent.path;

  var content = await entrypoint.readAsString();
  var lines = content.split('\n');
  var output = <String>[];

  var imports = <Import>[];

  alreadyConcatenated.add(entrypoint.absolute.path);

  void log([Object? message = "", bool gray = false]) {
    if (depth == 0) {
      stderr.writeln(gray ? message.toString().gray().dim() : message);
      return;
    }
    var all = "   " * (depth - 1) + "└─ $message";
    stderr.writeln(gray ? all.gray().dim() : all);
  }

  log('Concatenating ${p.relative(entrypoint.absolute.path, from: basePath)}');

  depth++;

  var currentComments = <String>[];

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];

    if (line.startsWith("//")) {
      currentComments.add(line);
    }

    if (line.startsWith('import ')) {
      var quoteChar = line[7];
      var specifier = line.substring(8, line.indexOf(quoteChar, 8));
      if (specifier.startsWith('dart:') || specifier.startsWith('package:')) {
        if (alreadyImported.contains(specifier)) {
          log('Skipping import $specifier', true);
          continue;
        }
        alreadyImported.add(specifier);

        if (currentComments.isNotEmpty && !specifier.startsWith('dart:')) {
          log('Importing $specifier + ${currentComments.length} comments');
          imports.add(Import(line, specifier, currentComments.toList()));
          currentComments.clear();
        } else {
          log('Importing $specifier');
          imports.add(Import(line, specifier));
        }

        continue;
      }

      var directory = entrypoint.absolute.parent;
      var file = File(p.normalize(p.join(directory.absolute.path, specifier)));

      if (alreadyConcatenated.contains(file.absolute.path)) {
        log('Already concatenated: ${p.relative(file.absolute.path, from: basePath)}',
            true);
        continue;
      }

      alreadyConcatenated.add(file.absolute.path);

      var source = await concatDartSource(
        file,
        alreadyImported,
        alreadyConcatenated,
        depth,
        basePath,
      );
      imports.addAll(source.imports);
      output.addAll(source.source);

      continue;
    }

    if (lines.sublist(i).any((l) => l.startsWith('import '))) {
      continue;
    }

    currentComments.clear();
    output.add(line);
  }

  return Source(imports, output);
}

void main(List<String> arguments) async {
  arguments = arguments.toList();

  var gdocs = arguments.remove("--gdocs");

  if (arguments.isEmpty) {
    print('need a <file>');
    exit(1);
  }

  var file = File(arguments[0]);
  var s = await concatDartSource(file);

  if (gdocs) {
    // google docs somehow trims a space for every indented line, so we need to
    // add an extra space to each
    print(s.toString().replaceAll(RegExp(r"^ ", multiLine: true), "  "));
  } else {
    print(s.toString());
  }
}
