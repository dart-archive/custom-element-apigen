#!/usr/bin/env dart
// Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
// This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
// The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
// The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
// Code distributed by Google as part of the polymer project is also
// subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'src/ast.dart';
import 'src/codegen.dart';
import 'src/config.dart';
export 'src/config.dart' show GlobalConfig;
import 'package:package_resolver/package_resolver.dart';

bool verbose = false;

// Allows a way to test things without actually writing to the file system.
typedef File FileFactory(String path);
File defaultCreateFile(String path) => new File(path);

Future<GlobalConfig> parseArgs(args, String program) async {
  if (args.length == 0) {
    print('usage: call this tool with either input files '
        'or a configuration file that describes input files and name '
        'substitutions. For example: ');
    print('    $program lib/src/x-a/x-a.html lib/src/x-b/x-c.html ...');
    print('    $program config.yaml');
    print('    $program config.yaml lib/src/x-a/x-a.html config2.yaml');
    exit(1);
  }

  PackageResolver resolver = await PackageResolver.loadConfig(".packages");

  var config = new GlobalConfig();
  config.packageResolver = resolver;
  for (var arg in args) {
    if (arg.endsWith('.html')) {
      config.files.add(new FileConfig(config, arg));
    } else if (arg.endsWith('.yaml')) {
      _progress('Parsing configuration ... ');
      await parseConfigFile(arg, config);
    }
  }

  return config;
}

Future generateWrappers(GlobalConfig config,
    {FileFactory createFile: defaultCreateFile}) async {
  var fileSummaries = [];
  var elementSummaries = {};
  var mixinSummaries = {};
  var len = config.files.length;
  int i = 0;

  // Parses a file at [path] into a [FileSummary] and adds everything found into
  // [fileSummaries], [elementSummaries], and [mixinSummaries].
  Future parseFile(String path, int totalLength) async {
    _progress('${++i} of $totalLength: $path');
    var summary = await _parseFile(path, config);
    fileSummaries.add(summary);
    for (var elementSummary in summary.elements) {
      elementSummary.summary = summary;
      var name = elementSummary.name;
      if (elementSummaries.containsKey(name)) {
        print('Error: found two elements with the same name ${name}');
        exit(1);
      }
      elementSummaries[name] = elementSummary;
    }
    for (var mixinSummary in summary.mixins) {
      mixinSummary.summary = summary;
      var name = mixinSummary.name;
      if (mixinSummaries.containsKey(name)) {
        print('Error: found two mixins with the same name ${name}');
        exit(1);
      }
      mixinSummaries[name] = mixinSummary;
    }
  }

  _progress('Parsing files... ');
  var parsedFilesLength = config.files.length + config.filesToLoad.length;
  await Future.forEach(config.files, (fileConfig) async {
    await parseFile(fileConfig.inputPath, parsedFilesLength);
  });
  await Future.forEach(config.filesToLoad,
      (path) async => await parseFile(path, parsedFilesLength));

  _progress('Running codegen... ');
  len = config.files.length;
  i = 0;
  config.files.forEach((fileConfig) {
    var inputPath = fileConfig.inputPath;
    var fileSummary = fileSummaries[i];
    _progress('${++i} of $len: $inputPath');

    var splitSummaries = fileSummary.splitByFile(fileConfig.file_overrides);
    splitSummaries.forEach((String filePath, FileSummary summary) {
      _generateDartApi(summary, elementSummaries, mixinSummaries, inputPath,
          fileConfig, filePath, createFile);
    });
  });

  // We assume that the file has to be there because of bower, even though we
  // could generate without.
  _progress('Checking original files exist for stubs');
  for (var inputPath in config.stubs.keys) {
    var file = new File(inputPath);
    if (!file.existsSync()) {
      print("error: stub file $inputPath doesn't exist");
      exit(1);
    }
  }

  _progress('Deleting files... ');
  _deleteFilesMatchingPatterns(config.deletionPatterns);

  _progress('Generating stubs... ');
  len = config.stubs.length;
  i = 0;
  config.stubs.forEach((inputPath, packageName) {
    _progress('${++i} of $len: $inputPath');
    _generateImportStub(inputPath, packageName, createFile);
  });

  _progress('Done');
  stdout.write('\n');
}

void _generateImportStub(
    String inputPath, String packageName, FileFactory createFile) {
  var file = createFile(inputPath);
  // File may have been deleted, make sure it still exists.
  file.createSync(recursive: true);

  var segments = path.split(inputPath);
  var newFileName =
      segments.last.replaceAll('-', '_').replaceAll('.html', '_nodart.html');
  var depth = segments.length;
  var goingUp = '../' * depth;
  var newPath = path.join(goingUp, 'packages/$packageName', newFileName);
  file.writeAsStringSync('<link rel="import" href="$newPath">\n'
      '$EMPTY_SCRIPT_WORKAROUND_ISSUE_11');
}

/// Reads the contents of [inputPath], parses the documentation, and then
/// generates a FileSummary for it.
Future<FileSummary> _parseFile(String inputPath, GlobalConfig globalConfig,
    {bool ignoreFileErrors: false}) async {
  String scriptPath = (await globalConfig.packageResolver.resolveUri("package:custom_element_apigen/src/js/process_elements.sh")).toFilePath();

  //inputPath = path.absolute(inputPath);
  var results = await Process.run(scriptPath, [inputPath]);
  if (results.exitCode != 0 || results.stderr != '') _parseError(results);

  var jsonFileSummary;
  try {
    jsonFileSummary = JSON.decode(results.stdout);
    assert(jsonFileSummary is Map);
  } catch (e) {
    _parseError(results);
  }

  // Apply type_overrides early on!
  _applyTypeOverrides(inputPath, jsonFileSummary, globalConfig);

  return new FileSummary.fromJson(jsonFileSummary);
}

void _applyTypeOverrides(
    String inputPath, Map jsonFileSummary, GlobalConfig globalConfig) {
  // Get the file config matching inputPath, and bail if it has no overrides.
  var fileConfig = globalConfig.files.firstWhere(
      (file) => platformIndependentPath(file.inputPath) == inputPath,
      orElse: () => null);
  if (fileConfig == null || fileConfig.typeOverrides == null) return;

  // Apply each type override to the jsonFileSummary.
  fileConfig.typeOverrides.forEach((String className, Map details) {
    // Find the summary for the class, it could be either an element or a
    // behavior.
    var jsonClass = jsonFileSummary['elements'][className];
    if (jsonClass == null) {
      jsonClass = jsonFileSummary['behaviors'][className];
    }
    if (jsonClass == null) {
      throw 'Unable to find class $className in file at $inputPath';
    }

    // Apply the type overrides for each named property.
    details.forEach((String propertyName, Map propertyDetail) {
      var jsonProperty = jsonClass['properties'][propertyName];
      if (jsonProperty == null) {
        throw 'unable to find property $propertyName in class $className';
      }

      jsonProperty['type'] = propertyDetail['type'];
    });
  });
}

_parseError(ProcessResult results) {
  throw '''
Failed to parse element files!

exit code: ${results.exitCode}
stderr: ${results.stderr}
stdout: ${results.stdout}
''';
}

/// Takes a FileSummary, and generates a Dart API for it. The input code must be
/// under lib/src/ (for example, lib/src/x-tag/x-tag.html), the output will be
/// generated under lib/ (for example, lib/x_tag/x_tag.dart).
///
/// If [fileName] is supplied then that will be used as the prefix for all
/// output files.
void _generateDartApi(
    FileSummary summary,
    Map<String, Element> elementSummaries,
    Map<String, Mixin> mixinSummaries,
    String inputPath,
    FileConfig config,
    String filePath,
    FileFactory createFile) {
  _progressLineBroken = false;
  var segments = path.split(inputPath);
  if (segments.length < 4 ||
      segments[0] != 'lib' ||
      segments[1] != 'src' ||
      !segments.last.endsWith('.html')) {
    print('error: expected $inputPath to be of the form '
        'lib/src/x-tag/**/x-tag2.html');
    exit(1);
  }

  var dashName = path.joinAll(segments.getRange(2, segments.length));
  // Use the filename if overridden.
  var name = filePath != null
      ? filePath
      : path.withoutExtension(segments.last).replaceAll('-', '_');
  var isSubdir = segments.length > 4;
  var outputDirSegments = ['lib'];
  if (isSubdir) {
    outputDirSegments.addAll(segments
        .getRange(2, segments.length - 1)
        .map((s) => s.replaceAll('-', '_')));
  }
  var packageLibDir = (isSubdir) ? '../' * (segments.length - 3) : '';
  var outputDir = path.joinAll(outputDirSegments);

  // Create the dart file.
  var dartContent = new StringBuffer();
  dartContent.write(generateDirectives(
      name, segments, summary, config, packageLibDir, mixinSummaries));
  var first = true;
  for (var element in summary.elements) {
    if (!first) dartContent.write('\n\n');
    dartContent.write(
        generateClass(element, config, elementSummaries, mixinSummaries));
    first = false;
  }
  for (var mixin in summary.mixins) {
    if (!first) dartContent.write('\n\n');
    dartContent
        .write(generateClass(mixin, config, elementSummaries, mixinSummaries));
    first = false;
  }
  createFile(path.join(outputDir, '$name.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync(dartContent.toString());

  // Create the main html file, this contains an import to the *_nodart.html
  // file, as well as other imports and a script pointing to the dart file.
  var extraImports = new StringBuffer();
  for (var jsImport in summary.imports) {
    var import = getImportPath(jsImport, config, segments, packageLibDir);
    if (import == null) continue;
    extraImports.write('<link rel="import" href="$import">\n');
  }

  var mainHtml = '''
<link rel="import" href="${name}_nodart.html">
$extraImports
<script type="application/dart" src="$name.dart"></script>\n
''';
  createFile(path.join(outputDir, '$name.html'))
    ..createSync(recursive: true)
    ..writeAsStringSync(mainHtml);

  // Create the *_nodart.html file. This contains all the other html imports.
  var noDartExtraImports =
      extraImports.toString().replaceAll('.html', '_nodart.html');
  var htmlBody = '''
<link rel="import" href="${packageLibDir}src/$dashName">
$noDartExtraImports
''';
  createFile(path.join(outputDir, '${name}_nodart.html'))
    ..createSync(recursive: true)
    ..writeAsStringSync('$htmlBody');
}

void _deleteFilesMatchingPatterns(List<RegExp> patterns) {
  new Directory(path.join('lib', 'src'))
      .listSync(recursive: true, followLinks: false)
      .where((file) => patterns.any((pattern) => path
          .relative(file.path, from: path.join('lib', 'src'))
          .contains(pattern)))
      .forEach((file) {
    if (file.existsSync()) file.deleteSync(recursive: true);
  });
}

int _lastLength = 0;
_progress(String msg) {
  const ESC = '\x1b';
  stdout.write('\r$ESC[32m$msg$ESC[0m');
  var len = msg.length;
  if (len < _lastLength && !verbose) {
    stdout.write(' ' * (_lastLength - len));
  }
  _lastLength = len;
}

bool _progressLineBroken = false;
_showMessage(String msg) {
  if (!verbose) return;
  if (!_progressLineBroken) {
    _progressLineBroken = true;
    stdout.write('\n');
  }
  print(msg);
}

const String EMPTY_SCRIPT_WORKAROUND_ISSUE_11 = '''
<script>
// This empty script is here to workaround issue
// https://github.com/dart-lang/core-elements/issues/11
</script>''';
