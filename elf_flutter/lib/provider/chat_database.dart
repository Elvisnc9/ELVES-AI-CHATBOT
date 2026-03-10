import 'package:elf_flutter/data/database/chat_dao.dart';
import 'package:elf_flutter/data/database/chat_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatDatabaseProvider = Provider<ChatDatabase>((ref) {
  final db = ChatDatabase();

  ref.onDispose(() {
    db.close();
  });

  return db;
});


final chatDaoProvider = Provider<ChatDao>((ref) {
  final db = ref.watch(chatDatabaseProvider);
  return ChatDao(db);
});
