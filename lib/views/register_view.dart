import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter email',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter password',
            ),
          ),
          TextButton(
              onPressed: () {
                final email = _email.text;
                final password = _password.text;

                try {
                  if (email.isNotEmpty && password.isNotEmpty) {
                    final credential = FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                            email: email, password: password);
                    debugPrint(credential.toString());
                  }
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'weak-password') {
                    print('User entered a weak password');
                  } else if (e.code == 'email-already-in-use') {
                    debugPrint('Email is already in use');
                  } else if (e.code == 'invalid-email') {
                    debugPrint('Invalid email entered');
                  }
                }
              },
              child: const Text('Register'))
        ],
      ),
    );
  }
}
