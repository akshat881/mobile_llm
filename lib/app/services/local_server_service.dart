import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import '../../presentation/screens/server_screen.dart' show LogEntry, LogType;
import '../data/models/chat_message.dart';
import 'inference_service.dart';

class LocalServerService extends GetxService {
  final InferenceService _inferenceService = Get.find<InferenceService>();

  HttpServer? _server;
  final RxBool isRunning = false.obs;
  final RxString serverIp = '0.0.0.0'.obs;
  final RxInt serverPort = 1234.obs;

  final RxList<LogEntry> logs = <LogEntry>[].obs;

  Future<void> startServer({bool exposeToNetwork = true}) async {
    if (isRunning.value) return;

    try {
      final ip = exposeToNetwork ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;
      _server = await HttpServer.bind(ip, serverPort.value);
      isRunning.value = true;
      serverIp.value = exposeToNetwork ? '0.0.0.0' : '127.0.0.1';

      _addLog(LogType.info, 'Server started on ${serverIp.value}:${serverPort.value}');

      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
    } catch (e) {
      _addLog(LogType.info, 'Failed to start server: $e');
      isRunning.value = false;
    }
  }

  Future<void> stopServer() async {
    if (!isRunning.value) return;

    await _server?.close(force: true);
    _server = null;
    isRunning.value = false;
    _addLog(LogType.info, 'Server stopped');
  }

  void clearLogs() {
    logs.clear();
  }

  void _addLog(LogType type, String message, {String? status, String? duration, String? payload}) {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    logs.insert(0, LogEntry(
      type: type,
      time: timeString,
      message: message,
      status: status,
      duration: duration,
      payload: payload,
    ));

    // Keep only last 100 logs to prevent memory bloat
    if (logs.length > 100) {
      logs.removeLast();
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final stopwatch = Stopwatch()..start();
    final method = request.method;
    final path = request.uri.path;
    final logType = method == 'GET' ? LogType.get : (method == 'POST' ? LogType.post : LogType.info);

    // CORS Headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Authorization');

    if (method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      if (path == '/v1/models' && method == 'GET') {
        await _handleGetModels(request);
        _addLog(logType, path, status: '200 OK', duration: '${stopwatch.elapsedMilliseconds}ms');
      } else if (path == '/v1/chat/completions' && method == 'POST') {
        await _handleChatCompletions(request, stopwatch);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not Found');
        request.response.close();
        _addLog(logType, path, status: '404 Not Found', duration: '${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal Server Error: $e');
      await request.response.close();
      _addLog(LogType.info, path, status: '500 Error', duration: '${stopwatch.elapsedMilliseconds}ms', payload: e.toString());
    }
  }

  Future<void> _handleGetModels(HttpRequest request) async {
    final modelName = _inferenceService.isModelLoaded.value 
        ? _inferenceService.currentModelName.value 
        : 'no-model-loaded';

    final response = {
      'object': 'list',
      'data': [
        {
          'id': modelName,
          'object': 'model',
          'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'owned_by': 'lm-studio-mobile',
        }
      ]
    };

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    await request.response.close();
  }

  Future<void> _handleChatCompletions(HttpRequest request, Stopwatch stopwatch) async {
    if (!_inferenceService.isModelLoaded.value) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(jsonEncode({'error': 'No model loaded'}));
      await request.response.close();
      _addLog(LogType.post, '/v1/chat/completions', status: '503 Service Unavailable', duration: '${stopwatch.elapsedMilliseconds}ms');
      return;
    }

    final content = await utf8.decoder.bind(request).join();
    _addLog(LogType.post, '/v1/chat/completions', payload: content);
    
    final Map<String, dynamic> body = jsonDecode(content);
    final List<dynamic> messagesRaw = body['messages'] ?? [];
    final bool stream = body['stream'] ?? false;

    // Convert to ChatMessage models
    final List<ChatMessage> messages = messagesRaw.map((m) {
      final roleStr = m['role'] as String;
      MessageRole role = MessageRole.user;
      if (roleStr == 'assistant') role = MessageRole.assistant;
      if (roleStr == 'system') role = MessageRole.system;
      return ChatMessage(content: m['content'] as String, role: role);
    }).toList();

    request.response.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
    request.response.headers.add('Cache-Control', 'no-cache');
    request.response.headers.add('Connection', 'keep-alive');

    final messageId = 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}';
    final created = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final modelName = _inferenceService.currentModelName.value;

    try {
      final tokenStream = _inferenceService.chat(messages);
      
      if (stream) {
        await for (final token in tokenStream) {
          final chunk = {
            'id': messageId,
            'object': 'chat.completion.chunk',
            'created': created,
            'model': modelName,
            'choices': [
              {
                'index': 0,
                'delta': {'content': token},
                'finish_reason': null
              }
            ]
          };
          request.response.write('data: ${jsonEncode(chunk)}\n\n');
          await request.response.flush();
        }
        
        // Send final chunk
        final finalChunk = {
          'id': messageId,
          'object': 'chat.completion.chunk',
          'created': created,
          'model': modelName,
          'choices': [
            {
              'index': 0,
              'delta': {},
              'finish_reason': 'stop'
            }
          ]
        };
        request.response.write('data: ${jsonEncode(finalChunk)}\n\n');
        request.response.write('data: [DONE]\n\n');
      } else {
        // Non-streaming
        final buffer = StringBuffer();
        await for (final token in tokenStream) {
          buffer.write(token);
        }
        
        final response = {
          'id': messageId,
          'object': 'chat.completion',
          'created': created,
          'model': modelName,
          'choices': [
            {
              'index': 0,
              'message': {
                'role': 'assistant',
                'content': buffer.toString()
              },
              'finish_reason': 'stop'
            }
          ],
          'usage': {
            'prompt_tokens': 0,
            'completion_tokens': buffer.toString().split(' ').length,
            'total_tokens': 0
          }
        };
        request.response.write(jsonEncode(response));
      }
      
      await request.response.close();
      _addLog(LogType.post, '/v1/chat/completions', status: '200 OK', duration: '${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      } catch (_) {}
      _addLog(LogType.info, '/v1/chat/completions', status: '500 Error', duration: '${stopwatch.elapsedMilliseconds}ms', payload: e.toString());
    }
  }
}
