import 'package:bloc/bloc.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'auth_event.dart';

import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider) : super(const AuthStateLoading()) {
    //initialize
    on<AuthEventInitialize>(
      (_, emit) async {
        await provider.initialze();
        final user = provider.currentUser;
        if (user == null) {
          emit(const AuthStateLoggedOut(null));
        } else if (!user.isEmailVerified) {
          emit(const AuthStateNeedsVerification());
        } else {
          emit(AuthStateLoggedIn(user));
        }
      },
    );

    //login event
    on<AuthEventLogin>(
      (event, emit) async {
        final email = event.email;
        final password = event.password;
        try {
          final user = await provider.login(email: email, password: password);
          emit(AuthStateLoggedIn(user));
        } on Exception catch (e) {
          emit(AuthStateLoggedOut(e));
        }
      },
    );

    //logout event
    on<AuthEventLogout>(
      (event, emit) async {
        try {
          emit(const AuthStateLoading());
          await provider.logOut();
          emit(const AuthStateLoggedOut(null));
        } on Exception catch (e) {
          emit(AuthStateLogoutFailure(e));
        }
      },
    );
  }
}
