import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generics/generic_dialog.dart';

Future<void> showCannotShareEmptyTextDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: 'Sharing',
    content: 'You can not share an empty text',
    optionsBuilder: () => {'Ok': null},
  );
}
