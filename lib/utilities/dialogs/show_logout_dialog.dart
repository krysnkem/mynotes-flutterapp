import 'package:flutter/material.dart';

import 'generics/generic_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Log out',
    content: "Are you sure you want to log out",
    optionsBuilder: () => {
      'No': false,
      'Yes': true,
    },
  ).then((value) => value ?? false);
}
