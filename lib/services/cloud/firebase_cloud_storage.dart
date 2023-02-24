import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';

import 'cloud_note.dart';
import 'cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final document = await notes.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
    });
    final fetchedNote = await document.get();
    return CloudNote(
      documentId: fetchedNote.id,
      ownerUserId: ownerUserId,
      text: '',
    );
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) {
    /// => Get a stream of Query snaphots from the notes collection on cloud firestore
    /// => Unwrap and get the list of Query snapshot of documents from the stream of Query snapshots
    /// => Convert the list of Query snapshot of documments into list of cloud notes
    /// => in the list of cloud notes filter out notes for the user using the owner id
    ////
    return notes.snapshots().map((event) => event.docs
        .map((doc) => CloudNote.fromSnapShot(doc))
        .where((note) => note.ownerUserId == ownerUserId));
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
  }) async {
    try {
      await notes.doc(documentId).update({textFieldName: text});
    } catch (_) {
      throw CouldNotUpdateNoteException();
    }
  }

  // Future<CloudNote> getNote({
  //   required String documentId,
  // }) async {
  //   try {
  //     final noteMap = await notes.doc(documentId).get();
  //     return CloudNote.fromDocSnapShot(noteMap);
  //   } catch (_) {
  //     throw CouldNotGetNoteException();
  //   }
  // }

  Future<void> deleteNote({
    required String documentId,
  }) async {
    try {
      await notes.doc(documentId).delete();
    } catch (_) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<Iterable<CloudNote>> getNotes({
    required String ownerUserId,
  }) async {
    try {
      return await notes
          .where(
            ownerUserIdFieldName,
            isEqualTo: ownerUserId,
          )
          .get()
          .then(
            (value) => value.docs.map(
              (snapshot) {
                return CloudNote.fromSnapShot(snapshot);
              },
            ),
          );
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  FirebaseCloudStorage._sharedInstance();
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}

// extension GetSingleton<T> on Object{
//   Object._sharedInstance();
//   static final T _shared = Object._sharedInstance();
  
//   T getSingleton<T>(){
//     return _shared;
//   }
// }
