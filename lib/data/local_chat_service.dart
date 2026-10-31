import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_server_config.dart';

class ChatTurn {
  const ChatTurn({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class AssistantServiceException implements Exception {
  const AssistantServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef ChatResponseGenerator =
    Future<String?> Function(List<ChatTurn> conversation);

class LocalChatService {
  LocalChatService({
    http.Client? client,
    String? baseUrl,
    String? token,
    ChatResponseGenerator? generateResponse,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? LocalServerConfig.baseUrl).replaceFirst(
         RegExp(r'/$'),
         '',
       ),
       _token = token ?? LocalServerConfig.token,
       _responseGenerator = generateResponse;

  final http.Client _client;
  final String _baseUrl;
  final String _token;
  final ChatResponseGenerator? _responseGenerator;

  Future<String> sendMessage(List<ChatTurn> conversation) async {
    if (conversation.isEmpty) {
      throw const AssistantServiceException('اكتب سؤالك أولًا.');
    }

    try {
      final response =
          await (_responseGenerator == null
                  ? _sendToLocalServer(conversation)
                  : _responseGenerator(conversation))
              .timeout(const Duration(seconds: 100));
      final text = response?.trim();
      if (text == null || text.isEmpty) {
        throw const AssistantServiceException(
          'وصل رد فارغ من النموذج المحلي. حاول مرة أخرى.',
        );
      }
      return text;
    } on AssistantServiceException {
      rethrow;
    } on TimeoutException {
      throw const AssistantServiceException(
        'استغرق النموذج المحلي وقتًا طويلًا. تأكد من تشغيل Ollama على اللابتوب.',
      );
    } on http.ClientException catch (error) {
      throw AssistantServiceException(
        'تعذر الاتصال بسيرفر اللابتوب على $_baseUrl. (${error.message})',
      );
    } on FormatException {
      throw const AssistantServiceException(
        'السيرفر المحلي أرسل ردًا غير صالح.',
      );
    }
  }

  Future<String?> _sendToLocalServer(List<ChatTurn> conversation) async {
    final request = http.Request('POST', Uri.parse('$_baseUrl/api/chat'))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({
        'messages': conversation
            .map(
              (turn) => {
                'role': turn.isUser ? 'user' : 'assistant',
                'text': turn.text,
              },
            )
            .toList(),
      });
    if (_token.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $_token';
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AssistantServiceException('رد السيرفر المحلي غير صالح.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['error'];
      throw AssistantServiceException(
        message is String ? message : 'تعذر الحصول على رد من النموذج المحلي.',
      );
    }
    final text = decoded['text'];
    if (text == null) return null;
    if (text is String) return text;
    throw const AssistantServiceException('السيرفر المحلي أرسل ردًا غير صالح.');
  }
}
