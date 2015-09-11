library e2e_test.mock_file;

import 'dart:convert';
import 'dart:io';

class MockFile implements File {
  static List<MockFile> createdFiles = <MockFile>[];
  String contents = '';
  final String path;

  MockFile(this.path);

  void createSync({bool recursive: false}) {
    createdFiles.add(this);
  }

  void writeAsStringSync(String contents, {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8, bool flush: false}) {
    this.contents += contents;
  }

  noSuchMethod(_) {
    throw new UnimplementedError();
  }
}
