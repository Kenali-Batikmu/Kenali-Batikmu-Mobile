import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/config/env_config.dart';
import 'package:batikmu/core/services/email_service.dart';
import 'package:batikmu/core/services/supabase_service.dart';
import '../test_helper.dart';

typedef _MockResponder = Future<_MockHttpReply> Function(
  String method,
  Uri uri,
  Map<String, String> headers,
  String body,
);

class _MockHttpReply {
  final int statusCode;
  final String body;
  const _MockHttpReply(this.statusCode, this.body);
}

class _MockHttpClient implements HttpClient {
  final _MockResponder responder;
  _MockHttpClient(this.responder);

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(method, url, responder);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  final String _method;
  final Uri _uri;
  final _MockResponder _responder;
  final _MockHttpHeaders _headers = _MockHttpHeaders();
  final List<int> _buffer = [];

  _MockHttpClientRequest(this._method, this._uri, this._responder);

  @override
  Encoding encoding = utf8;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  int contentLength = -1;

  @override
  HttpHeaders get headers => _headers;

  @override
  Uri get uri => _uri;

  @override
  String get method => _method;

  @override
  void add(List<int> data) => _buffer.addAll(data);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _buffer.addAll(chunk);
    }
  }

  @override
  void write(Object? object) => _buffer.addAll(utf8.encode(object.toString()));

  @override
  Future<HttpClientResponse> close() async {
    final bodyStr = utf8.decode(_buffer);
    final reply = await _responder(_method, _uri, _headers.toFlatMap(), bodyStr);
    return _MockHttpClientResponse(reply.statusCode, reply.body);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _map = {};

  Map<String, String> toFlatMap() =>
      _map.map((k, v) => MapEntry(k.toLowerCase(), v.join(',')));

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _map.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _map.forEach(action);
  }

  @override
  String? value(String name) => _map[name.toLowerCase()]?.first;

  @override
  List<String>? operator [](String name) => _map[name.toLowerCase()];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final int _statusCode;
  final List<int> _bodyBytes;
  final _MockHttpHeaders _headers = _MockHttpHeaders();

  _MockHttpClientResponse(this._statusCode, String body)
      : _bodyBytes = utf8.encode(body);

  @override
  int get statusCode => _statusCode;

  @override
  String get reasonPhrase => _statusCode == 200 ? 'OK' : 'ERROR';

  @override
  int get contentLength => _bodyBytes.length;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bodyBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setupTestEnvironment();

  group('QC Integration Tests: EmailService HTTP Contract & Security', () {
    setUp(() {
      EnvConfig.resetForTest();
    });

    tearDown(() {
      EnvConfig.resetForTest();
    });

    test('mengirim payload POST JSON valid ke endpoint EmailJS dan memproses HTTP 200', () async {
      EnvConfig.loadFromString('''
EMAILJS_SERVICE_ID=srv_qc_test
EMAILJS_TEMPLATE_ID=tpl_qc_test
EMAILJS_PUBLIC_KEY=pub_qc_test
''');

      Uri? capturedUri;
      String? capturedMethod;
      Map<String, dynamic>? capturedJson;

      final result = await HttpOverrides.runZoned(
        () => EmailService.sendPasswordResetOtp(
          recipientEmail: 'qc@batikmu.id',
          recipientName: 'Penguji QC',
          otpCode: '4829',
        ),
        createHttpClient: (_) => _MockHttpClient((method, uri, headers, body) async {
          capturedMethod = method;
          capturedUri = uri;
          capturedJson = jsonDecode(body) as Map<String, dynamic>;
          return const _MockHttpReply(200, 'OK');
        }),
      );

      expect(result.isSuccess, isTrue);
      expect(result.isDemoSimulated, isFalse);
      expect(capturedMethod, equals('POST'));
      expect(capturedUri.toString(), equals('https://api.emailjs.com/api/v1.0/email/send'));
      expect(capturedJson?['service_id'], equals('srv_qc_test'));
      expect(capturedJson?['template_id'], equals('tpl_qc_test'));
      expect(capturedJson?['user_id'], equals('pub_qc_test'));
      expect(capturedJson?['template_params']['to_email'], equals('qc@batikmu.id'));
      expect(capturedJson?['template_params']['otp_code'], equals('4829'));
    });

    test('menangani HTTP 500 dari server EmailJS dengan gagal aman (isSuccess: false)', () async {
      EnvConfig.loadFromString('''
EMAILJS_SERVICE_ID=srv_qc_test
EMAILJS_TEMPLATE_ID=tpl_qc_test
EMAILJS_PUBLIC_KEY=pub_qc_test
''');

      final result = await HttpOverrides.runZoned(
        () => EmailService.sendPasswordResetOtp(
          recipientEmail: 'qc@batikmu.id',
          recipientName: 'Penguji QC',
          otpCode: '1234',
        ),
        createHttpClient: (_) => _MockHttpClient(
          (method, uri, headers, body) async => const _MockHttpReply(500, 'Internal Server Error'),
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.isDemoSimulated, isFalse);
      expect(result.message, isNotEmpty);
    });

    test('menangani kegagalan jaringan (SocketException) secara anggun tanpa crash', () async {
      EnvConfig.loadFromString('''
EMAILJS_SERVICE_ID=srv_qc_test
EMAILJS_TEMPLATE_ID=tpl_qc_test
EMAILJS_PUBLIC_KEY=pub_qc_test
''');

      final result = await HttpOverrides.runZoned(
        () => EmailService.sendPasswordResetOtp(
          recipientEmail: 'qc@batikmu.id',
          recipientName: 'Penguji QC',
          otpCode: '9876',
        ),
        createHttpClient: (_) => _MockHttpClient((method, uri, headers, body) async {
          throw const SocketException('No Internet connection');
        }),
      );

      expect(result.isSuccess, isFalse);
      expect(result.isDemoSimulated, isFalse);
      expect(result.message.toLowerCase(), contains('gagal'));
    });

    test('[OWASP Security QC] kegagalan HTTP 403 non-browser tidak boleh membocorkan kode OTP mentah di respons', () async {
      EnvConfig.loadFromString('''
EMAILJS_SERVICE_ID=srv_qc_test
EMAILJS_TEMPLATE_ID=tpl_qc_test
EMAILJS_PUBLIC_KEY=pub_qc_test
''');

      const secretOtp = '7391';
      final result = await HttpOverrides.runZoned(
        () => EmailService.sendPasswordResetOtp(
          recipientEmail: 'qc@batikmu.id',
          recipientName: 'Penguji QC',
          otpCode: secretOtp,
        ),
        createHttpClient: (_) => _MockHttpClient(
          (method, uri, headers, body) async =>
              const _MockHttpReply(403, 'API calls are disabled for non-browser applications'),
        ),
      );

      // Standar keamanan OWASP MASVS: error autentikasi/otorisasi API email harus fail-closed
      // dan tidak boleh mengembalikan kode OTP mentah ke klien.
      expect(
        result.isSuccess,
        isFalse,
        reason: 'HTTP 403 dari EmailJS seharusnya dianggap gagal (fail-closed), bukan isSuccess: true',
      );
      expect(
        result.message,
        isNot(contains(secretOtp)),
        reason: 'Kode OTP rahasia tidak boleh dibocorkan pada pesan error klien',
      );
    });
  });

  group('QC Integration Tests: SupabaseService Offline & Fault Guards', () {
    setUp(() {
      EnvConfig.resetForTest();
    });

    tearDown(() {
      EnvConfig.resetForTest();
    });

    test('seluruh operasi cloud Supabase fail-safe tanpa crash saat kredensial belum dikonfigurasi', () async {
      final supabase = SupabaseService.instance;
      await supabase.initialize();

      expect(supabase.isReady, isFalse);
      expect(supabase.client, isNull);
      expect(await supabase.fetchMotifs(), isEmpty);
      expect(await supabase.fetchModules(), isEmpty);
      expect(await supabase.getUserByEmail('sekar@batikmu.id'), isNull);
      expect(
        await supabase.registerUser(
          name: 'QC User',
          email: 'qc@batikmu.id',
          passwordHash: 'hash_dummy',
        ),
        isFalse,
      );
      expect(
        await supabase.updateUserPassword(
          email: 'qc@batikmu.id',
          passwordHash: 'hash_baru',
        ),
        isFalse,
      );
      expect(
        await supabase.updateUserProfile(
          email: 'qc@batikmu.id',
          name: 'QC User Updated',
        ),
        isFalse,
      );
      expect(
        await supabase.saveQuizAttempt(
          userEmail: 'qc@batikmu.id',
          moduleId: 1,
          score: 80,
          passed: true,
        ),
        isFalse,
      );
      expect(
        await supabase.savePracticeScan(
          userEmail: 'qc@batikmu.id',
          moduleId: 1,
          confidence: 0.85,
          passed: true,
        ),
        isFalse,
      );
      expect(
        await supabase.syncUserModuleProgress(
          userEmail: 'qc@batikmu.id',
          moduleId: 1,
          progressPercent: 100,
          historyDone: true,
          characterDone: true,
          galleryDone: true,
          quizDone: true,
          practiceDone: true,
          quizScore: 90,
          practiceScore: 90,
          passingScore: 70,
          isPassed: true,
        ),
        isFalse,
      );
    });
  });
}
