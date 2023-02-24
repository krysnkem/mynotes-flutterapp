import 'package:flutter/material.dart';

import 'dialogs/generics/generic_dialog.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String text,
) {
  return showGenericDialog<void>(
      context: context,
      title: 'An error occured',
      content: text,
      optionsBuilder: () => {'Ok': null});
}
