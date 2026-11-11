/// Stub class for Web compilation where `dart:io` File is unavailable.
class File {
  final String path;
  File(this.path);

  bool existsSync() => false;
  int lengthSync() => 0;
  Future<void> delete() async {}
  Future<List<int>> readAsBytes() async => [];
  Future<File> writeAsBytes(List<int> bytes, {bool flush = false}) async => this;
  dynamic openSync() => _StubRandomAccessFile();
}

class _StubRandomAccessFile {
  List<int> readSync(int bytes) => [];
  void closeSync() {}
}

class Directory {
  final String path;
  Directory(this.path);

  bool existsSync() => false;
  Future<Directory> create({bool recursive = false}) async => this;
}
