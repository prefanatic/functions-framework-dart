// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Some utility methods for stagehand.
library;

import 'dart:convert' show base64, utf8;

import 'stagehand.dart';

final _substituteRegExp = RegExp(r'__([a-zA-Z]+)__');
final _nonValidSubstituteRegExp = RegExp('[^a-zA-Z]');

final _whiteSpace = RegExp(r'\s+');

List<TemplateFile> decodeConcatenatedData(List<String> data) {
  final results = <TemplateFile>[];

  for (var i = 0; i < data.length; i += 3) {
    final path = data[i];
    final type = data[i + 1];
    final raw = data[i + 2].replaceAll(_whiteSpace, '');

    final decoded = base64.decode(raw);

    if (type == 'binary') {
      results.add(TemplateFile.fromBinary(path, decoded));
    } else {
      final source = utf8.decode(decoded);
      results.add(TemplateFile(path, source));
    }
  }

  return results;
}

/// Convert a directory name into a reasonably legal pub package name.
String normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');

  // Strip any extension (like .dart).
  if (name.contains('.')) {
    name = name.substring(0, name.indexOf('.'));
  }

  return name;
}

/// Given a `String` [str] with mustache templates, and a [Map] of String key /
/// value pairs, substitute all instances of `__key__` for `value`. I.e.,
///
/// ```
/// Foo __projectName__ baz.
/// ```
///
/// and
///
/// ```
/// {'projectName': 'bar'}
/// ```
///
/// becomes:
///
/// ```
/// Foo bar baz.
/// ```
///
/// A key value can only be an ASCII string made up of letters: A-Z, a-z.
/// No whitespace, numbers, or other characters are allowed.
String substituteVars(String str, Map<String, String> vars) {
  if (vars.keys.any((element) => element.contains(_nonValidSubstituteRegExp))) {
    throw ArgumentError('vars.keys can only contain letters.');
  }

  return str.replaceAllMapped(_substituteRegExp, (match) {
    final item = vars[match[1]];

    if (item == null) {
      return match[0]!;
    } else {
      return item;
    }
  });
}

/// An abstract implementation of a [Generator].
abstract class DefaultGenerator extends Generator {
  DefaultGenerator(super.id, super.description, List<String> data) {
    for (var file in decodeConcatenatedData(data)) {
      addTemplateFile(file);
    }

    setEntrypoint(getFile('bin/server.dart'));
  }

  TemplateFile addFile(String path, String contents) =>
      addTemplateFile(TemplateFile(path, contents));

  @override
  String getInstallInstructions() =>
      "to provision required packages, run 'pub get'";
}
