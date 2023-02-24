import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_text_dialog.dart';
import '../../extensions/get_arguments.dart';
import '../../services/cloud/cloud_note.dart';
import '../../services/cloud/firebase_cloud_storage.dart';
import 'package:share_plus/share_plus.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  late TextEditingController _textEditingController;
  late FirebaseCloudStorage _notesService;

  Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    //get the note argument if any
    final widgetNote = context.getArgument<CloudNote>();

    if (widgetNote != null) {
      _note = widgetNote;
      _textEditingController.text = widgetNote.text;
      return widgetNote;
    }
    final existingNote = _note;

    if (existingNote != null) {
      return existingNote;
    } else {
      final currentUser = AuthService.firebase().currentUser!;
      final ownerUserId = currentUser.id;
      final note = await _notesService.createNewNote(ownerUserId: ownerUserId);
      _note = note;
      log('note created..');
      return note;
    }
  }

  void _textControllerListener() async {
    final note = _note;
    if (note == null) return;
    final text = _textEditingController.text;
    await _notesService.updateNote(
      documentId: note.documentId,
      text: text,
    );
  }

  void _setUpTextControllerListener() async {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      _notesService.deleteNote(documentId: note.documentId);
      log('note deleted....');
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textEditingController.text;
    if (note != null && text.isNotEmpty) {
      await _notesService.updateNote(documentId: note.documentId, text: text);
    }
  }

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _setTitle(context),
        actions: [
          IconButton(
            onPressed: () async {
              final text = _textEditingController.text;
              if (_note == null || text.isEmpty) {
                await showCannotShareEmptyTextDialog(context);
              } else {
                Share.share(text);
              }
            },
            icon: const Icon(Icons.share),
          )
        ],
      ),
      body: FutureBuilder(
          future: createOrGetExistingNote(context),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _setUpTextControllerListener();
                return TextField(
                  controller: _textEditingController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Start typing your note',
                  ),
                );
              default:
                return const Center(
                  child: CircularProgressIndicator(),
                );
            }
          }),
    );
  }

  Widget _setTitle(BuildContext context) {
    final widgetNote = context.getArgument<CloudNote>();
    if (widgetNote == null) {
      return const Text('New Note');
    } else {
      return const Text('Edit Note');
    }
  }
}
