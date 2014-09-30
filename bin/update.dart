#!/usr/bin/env dart
// Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
// This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
// The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
// The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
// Code distributed by Google as part of the polymer project is also
// subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:custom_element_apigen/generate_dart_api.dart' as generator;

main(args) {
  generator.GlobalConfig config =
      generator.parseArgs(args, 'pub run custom_elements_apigen:update');

  // TODO(sigmund): find out if we can use a bower override for this.
  var file = new File(path.join('lib', 'src', 'polymer', 'polymer.html'));
  if (!file.existsSync()) {
    print('error: lib/src/polymer/polymer.html not found. This tool '
        'requires that you first run `bower install`, and configure it '
        'to place all sources under `lib/src/`. See README for details.');
    exit(1);
  }

  generator.generateWrappers(config);

  // The file may be deleted at some point during the generator, make sure it
  // still exists.
  file.createSync(recursive: true);
  file.writeAsStringSync(_POLYMER_HTML_FORWARD);
}

const String _POLYMER_HTML_FORWARD = '''
<!--
Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
Code distributed by Google as part of the polymer project is also
subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt
-->

<!-- Dart note: load polymer for Dart and JS from the same place -->
<link rel="import" href="../../../../packages/polymer/polymer.html">
${generator.EMPTY_SCRIPT_WORKAROUND_ISSUE_11}
''';
