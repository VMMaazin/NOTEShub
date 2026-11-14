import 'dart:async';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/file_model.dart';
import 'package:mobile/core/services/device_download_service.dart';
import 'package:mobile/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceDownloadService Tests', () {
    const channelName = 'app.noteshub.mobile/device_download';
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    late Dio testDio;
    late DeviceDownloadService service;
    late io.Directory tempTestDir;

    final validPdfBytes = Uint8List.fromList([
      0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
      0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
      ...List.filled(100, 0x20),
    ]);

    final sampleFile = const FileModel(
      id: 'doc_101',
      semester: 5,
      subject: 1,
      module: 1,
      type: 'notes',
      name: 'Cloud Computing Unit 1.pdf',
      url: 'https://res.cloudinary.com/test/raw/upload/v1/notes.pdf',
      publicId: 'notes/cc1',
    );

    setUp(() {
      testDio = Dio();
      service = DeviceDownloadService(dio: testDio);
      tempTestDir = io.Directory.systemTemp.createTempSync('device_download_test_');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (call) async {
        return tempTestDir.path;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), null);

      if (tempTestDir.existsSync()) {
        try {
          tempTestDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('Valid Cloudinary PDF downloads and invokes Android save channel successfully', () async {
      String? channelMethodCalled;
      Map<dynamic, dynamic>? channelArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (call) async {
        channelMethodCalled = call.method;
        channelArgs = call.arguments as Map<dynamic, dynamic>?;
        return 'Downloads/Cloud_Computing_Unit_1.pdf';
      });

      testDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody(
          Stream.value(validPdfBytes),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/pdf'],
            Headers.contentLengthHeader: ['${validPdfBytes.length}'],
          },
        );
      });

      int progressReceived = 0;
      int progressTotal = 0;

      final result = await service.downloadToDevice(
        file: sampleFile,
        onProgress: (received, total) {
          progressReceived = received;
          progressTotal = total;
        },
      );

      expect(channelMethodCalled, equals('savePdfToDownloads'));
      expect(channelArgs?['fileName'], equals('Cloud Computing Unit 1.pdf'));
      expect(channelArgs?['filePath'], isNotNull);
      expect(result, contains('Cloud_Computing_Unit_1.pdf'));
      expect(progressReceived, greaterThan(0));
      expect(progressTotal, equals(validPdfBytes.length));
    });

    test('Failed HTTP status (e.g. 404) throws DioException and does not save', () async {
      bool channelCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (call) async {
        channelCalled = true;
        return null;
      });

      testDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody(
          Stream.value(Uint8List.fromList('Not Found'.codeUnits)),
          404,
          headers: {
            Headers.contentTypeHeader: ['text/plain'],
          },
        );
      });

      await expectLater(
        () => service.downloadToDevice(file: sampleFile),
        throwsA(isA<DioException>()),
      );

      expect(channelCalled, isFalse);
    });

    test('Corrupted/Non-PDF response (e.g. HTML error page with 200 status) throws StateError', () async {
      bool channelCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (call) async {
        channelCalled = true;
        return null;
      });

      final htmlBytes = Uint8List.fromList('<html><body>Error</body></html>'.codeUnits);
      testDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody(
          Stream.value(htmlBytes),
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        );
      });

      await expectLater(
        () => service.downloadToDevice(file: sampleFile),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('missing standard %PDF file signature'),
        )),
      );

      expect(channelCalled, isFalse);
    });

    test('Concurrent duplicate download attempts on the same file are rejected', () async {
      final completer = Completer<ResponseBody>();

      testDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return completer.future;
      });

      // Start first download (async, pending)
      final firstDownload = service.downloadToDevice(file: sampleFile);

      // Attempt second download on same file
      expect(
        () => service.downloadToDevice(file: sampleFile),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('already in progress'),
        )),
      );

      // Complete first download with valid response to finish cleanly
      completer.complete(
        ResponseBody(
          Stream.value(validPdfBytes),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/pdf'],
            Headers.contentLengthHeader: ['${validPdfBytes.length}'],
          },
        ),
      );

      await firstDownload;

      // Once finished, file can be downloaded again
      expect(service.isDownloading(sampleFile.id), isFalse);
    });

    test('Native channel failure is properly propagated as an exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (call) async {
        throw PlatformException(
          code: 'SAVE_FAILED',
          message: 'Storage permission denied or storage full.',
        );
      });

      testDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody(
          Stream.value(validPdfBytes),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/pdf'],
          },
        );
      });

      await expectLater(
        () => service.downloadToDevice(file: sampleFile),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          equals('SAVE_FAILED'),
        )),
      );
    });
  });

  group('ThemeController Default Appearance Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ThemeController.instance.resetForTesting();
    });

    test('Defaults to light theme on fresh start without saved preferences', () async {
      await ThemeController.instance.init();
      expect(ThemeController.instance.themeMode, equals(ThemeMode.light));
      expect(ThemeController.instance.isDarkMode, isFalse);
    });

    test('Toggle switch switches from light to dark and persists', () async {
      await ThemeController.instance.init();
      expect(ThemeController.instance.themeMode, equals(ThemeMode.light));

      await ThemeController.instance.toggleTheme();
      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));
      expect(ThemeController.instance.isDarkMode, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('noteshub_theme_mode'), equals('dark'));
    });

    test('Loads dark theme when dark theme was explicitly saved', () async {
      SharedPreferences.setMockInitialValues({'noteshub_theme_mode': 'dark'});
      ThemeController.instance.resetForTesting();

      await ThemeController.instance.init();
      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));
      expect(ThemeController.instance.isDarkMode, isTrue);
    });
  });
}
