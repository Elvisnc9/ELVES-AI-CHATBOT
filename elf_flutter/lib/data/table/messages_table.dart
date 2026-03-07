import 'package:drift/drift.dart';

class Messages extends Table {

  TextColumn get id => text()();

  TextColumn get conversationId => text()();

  TextColumn get role => text()();

  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
