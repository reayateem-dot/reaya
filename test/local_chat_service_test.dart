import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reaya/data/local_chat_service.dart';

void main() {
  test(
    'sends an authenticated conversation to the local chat endpoint',
    () async {
      final service = LocalChatService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url, Uri.parse('http://laptop.test/api/chat'));
          expect(request.headers['authorization'], 'Bearer test-token');
          expect(request.headers['content-type'], 'application/json');
          expect(jsonDecode(request.body), {
            'messages': [
              {'role': 'user', 'text': 'سؤال صحي'},
              {'role': 'assistant', 'text': 'رد سابق'},
            ],
          });
          return http.Response(
            jsonEncode({'text': 'إجابة محلية.'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        baseUrl: 'http://laptop.test/',
        token: 'test-token',
      );

      expect(
        await service.sendMessage([
          const ChatTurn(text: 'سؤال صحي', isUser: true),
          const ChatTurn(text: 'رد سابق', isUser: false),
        ]),
        'إجابة محلية.',
      );
    },
  );

  test('surfaces local chat server errors', () async {
    final service = LocalChatService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'شغّل Ollama على اللابتوب.'}),
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      baseUrl: 'http://laptop.test',
    );

    expect(
      () =>
          service.sendMessage([const ChatTurn(text: 'سؤال صحي', isUser: true)]),
      throwsA(
        isA<AssistantServiceException>().having(
          (error) => error.message,
          'message',
          'شغّل Ollama على اللابتوب.',
        ),
      ),
    );
  });

  test('reports invalid local chat server responses', () async {
    final service = LocalChatService(
      client: MockClient((_) async => http.Response('not json', 200)),
      baseUrl: 'http://laptop.test',
    );

    expect(
      () =>
          service.sendMessage([const ChatTurn(text: 'سؤال صحي', isUser: true)]),
      throwsA(
        isA<AssistantServiceException>().having(
          (error) => error.message,
          'message',
          'السيرفر المحلي أرسل ردًا غير صالح.',
        ),
      ),
    );
  });

  test('sends the conversation and returns the local model response', () async {
    final conversation = [
      const ChatTurn(text: 'ما دور طبيب الأطفال؟', isUser: true),
      const ChatTurn(text: 'يرعى صحة الطفل.', isUser: false),
      const ChatTurn(text: 'ومتى أزوره؟', isUser: true),
    ];
    final service = LocalChatService(
      generateResponse: (sentConversation) async {
        expect(sentConversation, conversation);
        return '  يرعى طبيب الأطفال صحة الطفل.  ';
      },
    );

    expect(
      await service.sendMessage(conversation),
      'يرعى طبيب الأطفال صحة الطفل.',
    );
  });

  test('rejects empty conversations without calling the local server', () {
    final service = LocalChatService(
      generateResponse: (_) => fail('The local server must not be called.'),
    );

    expect(
      () => service.sendMessage(const []),
      throwsA(
        isA<AssistantServiceException>().having(
          (error) => error.message,
          'message',
          'اكتب سؤالك أولًا.',
        ),
      ),
    );
  });

  test('shows local model setup errors from the server', () {
    final service = LocalChatService(
      generateResponse: (_) async => throw const AssistantServiceException(
        'شغّل Ollama على اللابتوب ونزّل النموذج المحلي.',
      ),
    );

    expect(
      () =>
          service.sendMessage([const ChatTurn(text: 'سؤال صحي', isUser: true)]),
      throwsA(
        isA<AssistantServiceException>().having(
          (error) => error.message,
          'message',
          contains('Ollama'),
        ),
      ),
    );
  });

  test('rejects empty local model responses', () {
    final service = LocalChatService(generateResponse: (_) async => '  ');

    expect(
      () =>
          service.sendMessage([const ChatTurn(text: 'سؤال صحي', isUser: true)]),
      throwsA(
        isA<AssistantServiceException>().having(
          (error) => error.message,
          'message',
          contains('وصل رد فارغ'),
        ),
      ),
    );
  });
}
