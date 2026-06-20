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

  Future<List<Message>> getMessages(String conversationId) {
    return (select(messages)
          ..where((tbl) => tbl.conversationId.equals(conversationId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
  }
  
    Future<List<Message>> getLastMessages(
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

  /// Total number of messages (user + assistant) saved for this
  /// conversation. Used to decide when a title-generation checkpoint
  /// has been reached.
  Future<int> getMessageCount(String conversationId) async {
    final rows = await (select(messages)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .get();
    return rows.length;
  }

  /// Returns the messages to feed into title generation at a checkpoint:
  /// the very first exchange (anchor, for topical continuity) plus the
  /// newest [recentWindow] messages (oldest-first), de-duplicated.
  ///
  /// This avoids re-sending the whole conversation while still keeping
  /// the title grounded in how the conversation started.
  Future<List<Message>> getTitleWindow(
    String conversationId, {
    int recentWindow = 12,
  }) async {
    final all = await getMessages(conversationId); // oldest-first
    if (all.isEmpty) return const [];

    final anchorCount = all.length >= 2 ? 2 : all.length;
    final anchor = all.sublist(0, anchorCount);

    final recentStart = all.length > recentWindow
        ? all.length - recentWindow
        : 0;
    final recent = all.sublist(recentStart);

    final seen = <String>{};
    final combined = <Message>[];
    for (final m in [...anchor, ...recent]) {
      if (seen.add(m.id)) combined.add(m);
    }
    return combined;
  }

Future<void> updateConversationTitle(
  String conversationId,
  String newTitle,
) {
  return (update(conversations)
        ..where((tbl) => tbl.id.equals(conversationId)))
      .write(
    ConversationsCompanion(
      title: Value(newTitle),
    ),
  );
}


Future<void> touchConversation(String conversationId) {
    return (update(conversations)
          ..where((tbl) => tbl.id.equals(conversationId)))
        .write(
      ConversationsCompanion(
        lastActiveAt: Value(DateTime.now()),
      ),
    );
  }

  /// Fetches a single conversation row by id, or null if it doesn't exist.
  Future<Conversation?> getConversation(String id) {
    return (select(conversations)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<Conversation>> watchAllConversations() {
  return (select(conversations)
        ..orderBy([
          (t) => OrderingTerm(
                expression: t.createdAt,
                mode: OrderingMode.desc,
              )
        ]))
      .watch();
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