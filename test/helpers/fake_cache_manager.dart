import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'fake_http_client.dart';

/// A [BaseCacheManager] that serves [kTransparentImage] for every URL from an
/// in-memory filesystem.
///
/// `FakeHttpOverrides` is not enough once images go through
/// `cached_network_image`: it uses its own `http` client rather than
/// `dart:io`'s, and the real `CacheManager` reaches for `path_provider` and
/// `sqflite` — both platform channels with no implementation under
/// `flutter_test`, so the image would fail with a `MissingPluginException`
/// instead of rendering.
///
/// Only [getFileStream] is exercised: it is the single method
/// `cached_network_image`'s `ImageLoader` calls to resolve bytes. The rest of
/// the interface throws, so a future code path that starts depending on it
/// fails loudly rather than silently doing nothing.
class FakeCacheManager implements BaseCacheManager {
  FakeCacheManager() : _fs = MemoryFileSystem();

  final MemoryFileSystem _fs;
  var _counter = 0;

  /// Every URL this fake has been asked for, in order — lets a test assert
  /// which TMDB size bucket a widget requested.
  final requestedUrls = <String>[];

  /// When true, every request fails — drives the error-widget branch.
  bool failAll = false;

  /// When set, bytes are withheld for this long — drives the placeholder
  /// branch, which is otherwise unobservable because the fake resolves within
  /// the frame.
  Duration? delay;

  File _fileFor(String url) {
    final file = _fs.file('/cache/${_counter++}.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(kTransparentImage);
    return file;
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool? withProgress,
  }) async* {
    requestedUrls.add(url);
    if (delay != null) await Future<void>.delayed(delay!);
    if (failAll) throw const HttpExceptionWithStatus(404, 'not found');
    yield FileInfo(_fileFor(url), FileSource.Cache, DateTime(2030), url);
  }

  Never _unused(String method) =>
      throw UnimplementedError('FakeCacheManager.$method is not stubbed');

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) => _unused('getSingleFile');

  @Deprecated('Prefer to use the new getFileStream method')
  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) => _unused('getFile');

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) => _unused('downloadFile');

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) => _unused('getFileFromCache');

  @override
  Future<FileInfo?> getFileFromMemory(String key) =>
      _unused('getFileFromMemory');

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => _unused('putFile');

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) => _unused('putFileStream');

  @override
  Future<void> removeFile(String key) => _unused('removeFile');

  @override
  Future<void> emptyCache() => _unused('emptyCache');

  @override
  Future<void> dispose() async {}
}
