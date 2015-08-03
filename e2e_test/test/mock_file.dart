library e2e_test.mock_file;

import 'dart:async';
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

  // Unimplemented methods.
  Future<MockFile> create({bool recursive: false}) => throw new UnimplementedError();
  Future<File> rename(String newPath) => throw new UnimplementedError();
  File renameSync(String newPath) => throw new UnimplementedError();
  Future<File> copy(String newPath) => throw new UnimplementedError();
  File copySync(String newPath) => throw new UnimplementedError();
  Future<int> length() => throw new UnimplementedError();
  int lengthSync() => throw new UnimplementedError();
  File get absolute => throw new UnimplementedError();
  Future<DateTime> lastModified() => throw new UnimplementedError();
  DateTime lastModifiedSync() => throw new UnimplementedError();
  Future<RandomAccessFile> open({FileMode mode: FileMode.READ}) =>
      throw new UnimplementedError();
  RandomAccessFile openSync({FileMode mode: FileMode.READ}) =>
      throw new UnimplementedError();
  Stream<List<int>> openRead([int start, int end]) =>
      throw new UnimplementedError();
  IOSink openWrite({FileMode mode: FileMode.WRITE, Encoding encoding: UTF8}) =>
      throw new UnimplementedError();
  Future<List<int>> readAsBytes() => throw new UnimplementedError();
  List<int> readAsBytesSync() => throw new UnimplementedError();
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      throw new UnimplementedError();
  String readAsStringSync({Encoding encoding: UTF8}) =>
      throw new UnimplementedError();
  Future<List<String>> readAsLines({Encoding encoding: UTF8}) =>
      throw new UnimplementedError();
  List<String> readAsLinesSync({Encoding encoding: UTF8}) =>
      throw new UnimplementedError();
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode: FileMode.WRITE, bool flush: false}) =>
      throw new UnimplementedError();
  void writeAsBytesSync(List<int> bytes,
          {FileMode mode: FileMode.WRITE, bool flush: false}) =>
      throw new UnimplementedError();
  Future<File> writeAsString(String contents, {FileMode mode: FileMode.WRITE,
          Encoding encoding: UTF8, bool flush: false}) =>
      throw new UnimplementedError();
  Future<FileStat> stat() => throw new UnimplementedError();
  FileStat statSync() => throw new UnimplementedError();
  Future<String> resolveSymbolicLinks() => throw new UnimplementedError();
  String resolveSymbolicLinksSync() => throw new UnimplementedError();
  Future<bool> exists() => throw new UnimplementedError();
  bool existsSync() => throw new UnimplementedError();
  Stream<FileSystemEvent> watch(
          {int events: FileSystemEvent.ALL, bool recursive: false}) =>
      throw new UnimplementedError();
  Future<FileSystemEntity> delete({bool recursive: false}) =>
      throw new UnimplementedError();
  void deleteSync({bool recursive: false}) => throw new UnimplementedError();
  get uri => throw new UnimplementedError();
  bool get isAbsolute => throw new UnimplementedError();
  Directory get parent => throw new UnimplementedError();
}
