import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import '../utilities/dialogs/show_logout_dialog.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify email',
        ),
        actions: [
          PopupMenuButton<MenuAction>(onSelected: (value) async {
            if (value == MenuAction.logout) {
              final shouldLogOut = await showLogoutDialog(context);
              if (shouldLogOut && mounted) {
                context.read<AuthBloc>().add(const AuthEventLogout());
              }
            }
          }, itemBuilder: (context) {
            return [
              const PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text('Log out'),
              )
            ];
          }),
        ],
      ),
      body: Column(
        children: [
          const Text(
            "We've sent a verification email, please open it to verify your account",
          ),
          const Text(
            "If you haven't received a verification email yet, please press the button below",
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventSendVerification());
            },
            child: const Text('Send email verification'),
          ),
          TextButton(
            onPressed: () async {
              context.read<AuthBloc>().add(const AuthEventLogout());
            },
            child: const Text('Restart'),
          )
        ],
      ),
    );
  }
}
