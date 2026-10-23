import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/core/database/local_database_schema.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@module
abstract class LocalDatabaseModule {
  @preResolve
  Future<Database> get database async {
    final path = join(
      await getDatabasesPath(),
      LocalDatabaseProperties.databaseName,
    );

    return openDatabase(
      path,
      version: LocalDatabaseSchema.version,
      onConfigure: LocalDatabaseSchema.onConfigure,
      onCreate: LocalDatabaseSchema.onCreate,
      onUpgrade: LocalDatabaseSchema.onUpgrade,
    );
  }
}
