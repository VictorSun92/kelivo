import 'package:flutter_test/flutter_test.dart';

import 'package:Kelivo/core/models/chat_message.dart';

void main() {
  group('ChatMessage groupId defaulting', () {
    test('groupId defaults to the generated id when neither is provided', () {
      final message = ChatMessage(
        role: 'user',
        content: 'hello',
        conversationId: 'conversation-1',
      );

      expect(message.groupId, isNotNull);
      expect(message.groupId, message.id);
    });

    test('groupId defaults to the explicit id when only id is provided', () {
      final message = ChatMessage(
        id: 'message-1',
        role: 'user',
        content: 'hello',
        conversationId: 'conversation-1',
      );

      expect(message.groupId, 'message-1');
    });

    test('explicit groupId is preserved', () {
      final message = ChatMessage(
        id: 'message-2',
        role: 'assistant',
        content: 'hi',
        conversationId: 'conversation-1',
        groupId: 'group-1',
      );

      expect(message.groupId, 'group-1');
    });

    test('copyWith keeps the original groupId', () {
      final message = ChatMessage(
        role: 'user',
        content: 'hello',
        conversationId: 'conversation-1',
      );

      final copy = message.copyWith(content: 'edited');

      expect(copy.groupId, message.groupId);
    });
  });
}
