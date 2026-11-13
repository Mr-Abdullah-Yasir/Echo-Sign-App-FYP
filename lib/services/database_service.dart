import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const String _databaseName = 'echo_sign.db';
  static const int _databaseVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(databaseDirectory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedSignVideos(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _seedSignVideos(db);
        }

        if (oldVersion < 3) {
          // Phase 1 Firebase migration:
          // old local accounts are intentionally discarded. Translation/favorite
          // rows linked to those old accounts are also removed.
          await db.delete('favorites');
          await db.delete('translations');
          await db.delete('users');

          final columns = await db.rawQuery('PRAGMA table_info(users)');
          final names = columns.map((row) => row['name'] as String).toSet();

          if (!names.contains('firebase_uid')) {
            await db.execute('ALTER TABLE users ADD COLUMN firebase_uid TEXT');
          }
          if (!names.contains('username')) {
            await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
          }

          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_firebase_uid '
            'ON users(firebase_uid)',
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_nocase '
            'ON users(username COLLATE NOCASE)',
          );
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT UNIQUE,
        username TEXT UNIQUE COLLATE NOCASE,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE COLLATE NOCASE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        english_text TEXT NOT NULL,
        asl_gloss TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        translation_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, translation_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (translation_id) REFERENCES translations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sign_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gloss TEXT NOT NULL UNIQUE COLLATE NOCASE,
        asset_path TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _seedSignVideos(Database db) async {
    const words = <String>[
      'I', 'YOU', 'HE', 'SHE', 'WE', 'THEY',
      'HOW', 'WHAT', 'WHERE', 'WHEN', 'WHO', 'WHY',
      'GO', 'COME', 'WANT', 'NEED', 'LIKE', 'HAVE',
      'SCHOOL', 'HOME', 'WORK', 'FOOD', 'WATER',
      'TODAY', 'TOMORROW', 'YESTERDAY',
      'GOOD', 'BAD', 'HAPPY', 'SAD',
      'YES', 'NO', 'PLEASE', 'THANK-YOU', 'HELP',
    ];

    final batch = db.batch();

    for (final gloss in words) {
      batch.insert(
        'sign_videos',
        {
          'gloss': gloss,
          'asset_path': 'assets/sign_videos/${gloss.toLowerCase()}.mp4',
          'is_available': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<AppUser?> findUserByFirebaseUid(String firebaseUid) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser> ensureFirebaseLocalUser({
    required String firebaseUid,
    required String username,
    required String fullName,
    required String email,
  }) async {
    final existing = await findUserByFirebaseUid(firebaseUid);
    if (existing != null) {
      final db = await database;
      await db.update(
        'users',
        {
          'username': username.trim().toLowerCase(),
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return (await findUserByFirebaseUid(firebaseUid))!;
    }

    final db = await database;
    final now = DateTime.now();

    final id = await db.insert(
      'users',
      {
        'firebase_uid': firebaseUid,
        'username': username.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        // Authentication is handled by Firebase Auth. These placeholders only
        // satisfy the legacy local schema used by history/profile modules.
        'password_hash': 'firebase_managed',
        'password_salt': 'firebase_managed',
        'created_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return AppUser(
      id: id,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: 'firebase_managed',
      passwordSalt: 'firebase_managed',
      createdAt: now,
    );
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [email.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> findUserById(int id) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser> createUser({
    required String fullName,
    required String email,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final db = await database;
    final createdAt = DateTime.now();

    final id = await db.insert(
      'users',
      {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password_hash': passwordHash,
        'password_salt': passwordSalt,
        'created_at': createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return AppUser(
      id: id,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: passwordHash,
      passwordSalt: passwordSalt,
      createdAt: createdAt,
    );
  }


  Future<AppUser> updateUserProfile({
    required int userId,
    required String fullName,
    required String email,
  }) async {
    final db = await database;
    await db.update(
      'users',
      {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
      },
      where: 'id = ?',
      whereArgs: [userId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    final updated = await findUserById(userId);
    if (updated == null) {
      throw StateError('Updated user could not be loaded.');
    }
    return updated;
  }

  Future<AppUser> updateUserPassword({
    required int userId,
    required String passwordHash,
    required String passwordSalt,
  }) async {
    final db = await database;
    await db.update('users', {
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
    }, where: 'id = ?', whereArgs: [userId]);
    final updated = await findUserById(userId);
    if (updated == null) throw StateError('Updated user could not be loaded.');
    return updated;
  }

  Future<void> addTranslation({
    required int userId,
    required String englishText,
    required String aslGloss,
  }) async {
    final db = await database;

    await db.insert(
      'translations',
      {
        'user_id': userId,
        'english_text': englishText.trim(),
        'asl_gloss': aslGloss.trim(),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> countTranslationsForUser(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM translations WHERE user_id = ?',
      [userId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }


  Future<List<Map<String, Object?>>> getTranslationsForUser(int userId) async {
    final db = await database;
    return db.rawQuery(
      """
      SELECT
        t.id, t.user_id, t.english_text, t.asl_gloss, t.created_at,
        CASE WHEN f.id IS NULL THEN 0 ELSE 1 END AS is_favorite
      FROM translations t
      LEFT JOIN favorites f
        ON f.translation_id = t.id AND f.user_id = ?
      WHERE t.user_id = ?
      ORDER BY t.id DESC
      """,
      [userId, userId],
    );
  }

  Future<void> deleteTranslation({
    required int userId,
    required int translationId,
  }) async {
    final db = await database;
    await db.delete(
      'translations',
      where: 'id = ? AND user_id = ?',
      whereArgs: [translationId, userId],
    );
  }

  Future<int> countFavoritesForUser(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM favorites WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, Object?>>> getFavoritesForUser(int userId) async {
    final db = await database;
    return db.rawQuery(
      """
      SELECT
        t.id, t.user_id, t.english_text, t.asl_gloss, t.created_at,
        1 AS is_favorite
      FROM favorites f
      INNER JOIN translations t ON t.id = f.translation_id
      WHERE f.user_id = ? AND t.user_id = ?
      ORDER BY f.id DESC
      """,
      [userId, userId],
    );
  }

  Future<bool> toggleFavorite({
    required int userId,
    required int translationId,
  }) async {
    final db = await database;
    final existing = await db.query(
      'favorites',
      columns: ['id'],
      where: 'user_id = ? AND translation_id = ?',
      whereArgs: [userId, translationId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'favorites',
        where: 'user_id = ? AND translation_id = ?',
        whereArgs: [userId, translationId],
      );
      return false;
    }

    await db.insert(
      'favorites',
      {
        'user_id': userId,
        'translation_id': translationId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return true;
  }

  Future<Map<String, dynamic>> exportUserBackup(int userId) async {
    final db = await database;
    final user = await findUserById(userId);

    if (user == null) {
      throw StateError('User account could not be loaded.');
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        t.english_text,
        t.asl_gloss,
        t.created_at,
        CASE WHEN f.id IS NULL THEN 0 ELSE 1 END AS is_favorite
      FROM translations t
      LEFT JOIN favorites f
        ON f.translation_id = t.id
        AND f.user_id = ?
      WHERE t.user_id = ?
      ORDER BY t.id ASC
      ''',
      [userId, userId],
    );

    return <String, dynamic>{
      'format': 'echosign_backup',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'profile': <String, dynamic>{
        'full_name': user.fullName,
        'email': user.email,
      },
      'translations': rows
          .map(
            (row) => <String, dynamic>{
              'english_text': row['english_text'],
              'asl_gloss': row['asl_gloss'],
              'created_at': row['created_at'],
              'is_favorite': (row['is_favorite'] as int? ?? 0) == 1,
            },
          )
          .toList(),
    };
  }

  Future<void> restoreUserBackup({
    required int userId,
    required Map<String, dynamic> backup,
  }) async {
    if (backup['format'] != 'echosign_backup' || backup['version'] != 1) {
      throw const FormatException(
        'Unsupported or invalid EchoSign backup file.',
      );
    }

    final profile = backup['profile'];
    final translations = backup['translations'];

    if (profile is! Map || translations is! List) {
      throw const FormatException('The backup file is incomplete.');
    }

    final fullName = profile['full_name'];
    final email = profile['email'];

    if (fullName is! String ||
        fullName.trim().isEmpty ||
        email is! String ||
        email.trim().isEmpty) {
      throw const FormatException('The backup profile is invalid.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final db = await database;

    await db.transaction((txn) async {
      final emailConflict = await txn.query(
        'users',
        columns: ['id'],
        where: 'email = ? COLLATE NOCASE AND id != ?',
        whereArgs: [normalizedEmail, userId],
        limit: 1,
      );

      if (emailConflict.isNotEmpty) {
        throw StateError(
          'The email in this backup belongs to another local account.',
        );
      }

      await txn.update(
        'users',
        {
          'full_name': fullName.trim(),
          'email': normalizedEmail,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      await txn.delete(
        'translations',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final raw in translations) {
        if (raw is! Map) {
          throw const FormatException(
            'A translation entry in the backup is invalid.',
          );
        }

        final englishText = raw['english_text'];
        final aslGloss = raw['asl_gloss'];
        final createdAt = raw['created_at'];
        final isFavorite = raw['is_favorite'];

        if (englishText is! String ||
            aslGloss is! String ||
            createdAt is! String) {
          throw const FormatException(
            'A translation entry in the backup is incomplete.',
          );
        }

        final translationId = await txn.insert(
          'translations',
          {
            'user_id': userId,
            'english_text': englishText.trim(),
            'asl_gloss': aslGloss.trim(),
            'created_at': createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        if (isFavorite == true) {
          await txn.insert(
            'favorites',
            {
              'user_id': userId,
              'translation_id': translationId,
              'created_at': createdAt,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  Future<String?> getSignVideoPath(String gloss) async {
    final db = await database;

    final rows = await db.query(
      'sign_videos',
      columns: ['asset_path'],
      where: 'gloss = ? COLLATE NOCASE AND is_available = 1',
      whereArgs: [gloss.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['asset_path'] as String?;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
