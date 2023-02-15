import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'package:mynotes/views/verfiy_email_view.dart';

void main() {
  runApp(MaterialApp(
    title: 'My Notes',
    home: const HomePage(),
    routes: {
      '/login/': (context) => const LoginView(),
      '/register/': (context) => const RegisterView()
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            return const Text('error occured');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                if (user.emailVerified) {
                  print('Email is verified');
                } else {
                  return const VerifyEmailView();
                }
              } else {
                return const LoginView();
              }
              // final emailVerified = user?.emailVerified ?? false;
              // if (emailVerified) {
              //   print('You are verified');
              // } else {
              //   print('You need to verify your email first');
              //   return const VerifyEmailView();
              // }
              // return const Text('done');
              return const Text('done!');

            default:
              return const Center(child: CircularProgressIndicator());
          }
        });
  }
}
