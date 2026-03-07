
import 'package:drift/drift.dart';
import 'package:elf_flutter/data/table/conservations_table.dart';
import 'package:elf_flutter/data/table/messages_table.dart';
import 'chat_database.dart';


part 'chat_dao.g.dart';

@DriftAccessor(tables: [Conversations, Messages])
class ChatDao extends DatabaseAccessor<ChatDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);
  Future<void> createConversation(ConversationsCompanion conversation) {
    return into(conversations).insert(conversation);
  }

    Future<void> saveMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  Future<List<dynamic>> getMessages(String conversationId) {
    return (select(messages)
          ..where((tbl) => tbl.conversationId.equals(conversationId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }
  
    Future<List<dynamic>> getLastMessages(
      String conversationId,
      int limit,
      ) {
    return (select(messages)
          ..where((tbl) => tbl.conversationId.equals(conversationId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }


  Future<List<dynamic>> getAllConversations() {
    return (select(conversations)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc)
          ]))
        .get();
  }


  Future<void> deleteConversation(String id) async {

    await (delete(messages)
          ..where((tbl) => tbl.conversationId.equals(id)))
        .go();

    await (delete(conversations)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}


