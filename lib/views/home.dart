import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/views/verfiy_email_view.dart';

import 'login_view.dart';
import 'notes/notes_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AuthService.firebase().initialze(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('error occured');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = AuthService.firebase().currentUser;
              if (user != null) {
                if (user.isEmailVerified) {
                  return const NotesView();
                } else {
                  return const VerifyEmailView();
                }
              } else {
                return const LoginView();
              }

            default:
              return const Center(
                child: CircularProgressIndicator(),
              );
          }
        });
  }
}
