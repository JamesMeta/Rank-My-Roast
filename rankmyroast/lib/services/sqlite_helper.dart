import 'package:rankmyroast/classes/modals/group.dart';
import 'package:rankmyroast/classes/modals/group_order.dart';
import 'package:sqflite/sqflite.dart';

class SqliteHelper {
  // 1. Create a private static instance of the class
  static final SqliteHelper _instance = SqliteHelper._internal();

  // 2. Provide a public constructor to access the instance
  factory SqliteHelper() => _instance;

  // 3. A private named constructor for the internal initialization
  SqliteHelper._internal();

  // 4. Cache the database connection
  static Database? _database;

  // Getter to safely retrieve or initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database file on the device
  Future<Database> _initDatabase() async {
    // Get the default databases path (e.g., /data/data/com.example/databases on Android)
    final dbPath = await getDatabasesPath();

    // Join the path with your database file name
    final path = '$dbPath/rankMyRoast.db';

    // Open the database and apply the schema version and creation callback
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Handle future migrations here
    );
  }

  // This runs the first time the database is created on the device
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groupOrder (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        group_index INTEGER NOT NULL
      )
    ''');
  }

  bool pastGroupsContainsCurrentGroups(
    List<Group> currentGroups,
    List<GroupOrder> pastGroups,
  ) {
    if (pastGroups.length != currentGroups.length) {
      return false;
    }

    for (var pastGroup in pastGroups) {
      if (currentGroups
          .where((group) => group.id == pastGroup.groupId)
          .isEmpty) {
        return false;
      }
    }

    return true;
  }

  Future<void> clearGroupOrdersForLegacyGroups(
    List<Group> currentGroups,
  ) async {
    final db = await database;

    // Get all group IDs from the current groups
    final currentGroupIds = currentGroups.map((group) => group.id).toList();

    // Delete records from groupOrder where the group_id is not in the currentGroupIds
    await db.delete(
      'groupOrder',
      where: 'group_id NOT IN (${currentGroupIds.map((_) => '?').join(', ')})',
      whereArgs: currentGroupIds,
    );
  }

  Future<List<GroupOrder>> getGroupOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> mapsRaw = await db.query('groupOrder');

    final maps = List<Map<String, dynamic>>.from(mapsRaw);

    // sort by index
    maps.sort((a, b) => a['group_index'].compareTo(b['group_index']));

    return List.generate(maps.length, (i) {
      return GroupOrder.fromMap(maps[i]);
    });
  }

  Future<void> upsertGroupOrder(List<Map<int, String>> groupOrders) async {
    final db = await database;

    final batch = db.batch();

    for (final groupOrder in groupOrders) {
      final index = groupOrder.keys.first;
      final groupId = groupOrder.values.first;

      // Check if the record already exists
      final existingRecords = await db.query(
        'groupOrder',
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      if (existingRecords.isNotEmpty) {
        // Update the existing record
        batch.update(
          'groupOrder',
          {'group_index': index},
          where: 'group_id = ?',
          whereArgs: [groupId],
        );
      } else {
        // Insert a new record
        batch.insert('groupOrder', {'group_id': groupId, 'group_index': index});
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteGroupOrder(String groupId) async {
    final db = await database;
    await db.delete('groupOrder', where: 'group_id = ?', whereArgs: [groupId]);
  }
}
