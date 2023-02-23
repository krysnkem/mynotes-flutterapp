import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:mynotes/extensions/list/filter.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;

class NotesService {
  Database? _db;
  List<DatabaseNote> _notes = [];

  DatabaseUser? _user;

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes =>
      _notesStreamController.stream.filter(
        (note) {
          final currentUser = _user;
          if (currentUser != null) {
            return note.userId == currentUser.id;
          } else {
            throw UserShouldBeSetBeforeReadingAllNotes();
          }
        },
      );

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        log('listen called');
        _cacheNotes();
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory NotesService() => _shared;

  Future<void> _cacheNotes() async {
    log('cache called...');
    final allnotes = await getAllNotes();
    _notes = allnotes.toList();
    _notesStreamController.add(_notes);
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseAlreadyOpenException();
    } else {
      return db;
    }
  }

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      //get the user
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CoulNotFindUserException {
      //if no user is found then create a user and return it
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  //create notes
  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    //ensure that the database is open
    await _ensureDbIsOpen();

    //get the database instace or throw an error if not opened
    final db = _getDatabaseOrThrow();
    //find the user in the database
    final dbUser = await getUser(email: owner.email);

    //ensure that owner with a given id exists in the database with the given email
    if (dbUser != owner) throw CoulNotFindUserException();

    const text = '';
    var values = {
      userIdColumn: owner.id,
      isSyncedWithCloudColumn: 1,
      textColumn: text
    };
    //insert an note with empty text in the database
    final noteId = await db.insert(
      noteTable,
      values,
    );

    //if the note was not created then throw an error
    if (noteId == 0) throw CouldNotCreateNoteException();
    //create a database note
    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    //add the note to list of notes
    _notes.add(note);
    //pass the list of notes to the stream controller
    _notesStreamController.add(_notes);
    // _cacheNotes();

    //return the note
    return note;
  }

  //delete note
  Future<void> deleteNote({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deleteCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleteCount == 0) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
      // _cacheNotes();
    }
  }

  //delete all notes
  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  //get note
  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (notes.isEmpty) throw CouldNotFindNoteException();
    final note = DatabaseNote.fromRow(notes.first);
    // _notes.removeWhere((note) => note.id == id);
    // _notes.add(note);
    // _notesStreamController.add(_notes);
    return note;
  }

  //get all notes
  Future<Iterable<DatabaseNote>> getAllNotes() async {
    log('Getting all notes');
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
    );
    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  //update note
  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    log('Update called...');

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);
    final updateCount = await db.update(
        noteTable, {textColumn: text, isSyncedWithCloudColumn: 0},
        where: "id=?", whereArgs: [note.id]);
    if (updateCount == 0) throw CoulNotUpdateNoteException();
    final updatedNote = await getNote(id: note.id);
    _notes.removeWhere((note) => note.id == updatedNote.id);
    _notes.add(updatedNote);
    _notesStreamController.add(_notes);
    // _cacheNotes();
    return updatedNote;
  }

  //ensure db is open
  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  }

  //opening and closing the database
  Future<void> open() async {
    if (_db != null) throw DatabaseAlreadyOpenException();
    try {
      final docPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);

      await db.execute(createNoteTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) throw DatabaseIsNotOpenException();
    await db.close();
    _db = null;
  }

  //create user
  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: "email = ?",
      whereArgs: [email.toLowerCase()],
    );

    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }
    final userId = await db.insert(
      userTable,
      {
        emailColumn: email.toLowerCase(),
      },
    );

    return DatabaseUser(id: userId, email: email);
  }

  //delete user
  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  //get user
  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    //check if the user exists
    final results = await db.query(
      userTable,
      where: 'email = ?',
      limit: 1,
      whereArgs: [email.toLowerCase()],
    );

    //throw an error if the user does not exists
    if (results.isEmpty) throw CoulNotFindUserException();
    return DatabaseUser.fromRow(results.first);
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID= $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud = map[isSyncedWithCloudColumn] as int == 0;

  @override
  String toString() =>
      'Note, id= $id, userId= $userId, isSyncedWithCloud= $isSyncedWithCloud, text= $text';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'notes';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';

const createNoteTable = '''CREATE TABLE IF NOT EXISTS "notes" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT,
	"is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY("user_id") REFERENCES "user"("id"),
	PRIMARY KEY("id" AUTOINCREMENT)
);''';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user"  (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
