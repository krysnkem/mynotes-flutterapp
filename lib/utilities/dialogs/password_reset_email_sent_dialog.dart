import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generics/generic_dialog.dart';

Future<void> showPasswordResetSentDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: 'Password Reset',
    content:
        'We have now sent you a password reset link. Please check email for more info',
    optionsBuilder: () => {
      'Ok': null,
    },
  );
}
