import 'package:flutter/material.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_logout_dialog.dart';

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
              if (shouldLogOut) {
                await AuthService.firebase().logOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (_) => false,
                  );
                }
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
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text('Send email verification'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().logOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginRoute,
                  (route) => false,
                );
              }
            },
            child: const Text('Restart'),
          )
        ],
      ),
    );
  }
}
