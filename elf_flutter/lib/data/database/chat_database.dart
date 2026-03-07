import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:elf_flutter/data/table/conservations_table.dart';
import 'package:elf_flutter/data/table/messages_table.dart';



part 'chat_database.g.dart';

@DriftDatabase(
  tables: [
    Conversations,
    Messages,
  ],
)
class ChatDatabase extends _$ChatDatabase {

  ChatDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'chat_db',
  );
}
