import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider)
      : super(const AuthStateUnitialized(isLoading: true)) {
    //send email verification
    on<AuthEventSendVerification>(
      (event, emit) async {
        await provider.sendEmailVerification();
        emit(state);
      },
    );

    //register
    on<AuthEventRegister>(
      (event, emit) async {
        try {
          final email = event.email;
          final password = event.password;
          await provider.createUser(email: email, password: password);
          await provider.sendEmailVerification();
          emit(const AuthStateNeedsVerification(isLoading: false));
        } on Exception catch (e) {
          emit(AuthStateRegistering(exception: e, isLoading: false));
        }
      },
    );
    //initialize
    on<AuthEventInitialize>(
      (_, emit) async {
        await provider.initialze();
        final user = provider.currentUser;
        if (user == null) {
          emit(const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ));
        } else if (!user.isEmailVerified) {
          log('not verified');
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(
            user: user,
            isLoading: false,
          ));
        }
      },
    );

    //login event
    on<AuthEventLogin>(
      (event, emit) async {
        log('logging in....');
        emit(const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
        ));
        final email = event.email;
        final password = event.password;

        try {
          final user = await provider.login(
            email: email,
            password: password,
          );
          if (!user.isEmailVerified) {
            // emit(const AuthStateLoggedOut(
            //   exception: null,
            //   isLoading: false,
            // ));
            log('user email not verified');
            emit(const AuthStateNeedsVerification(
              isLoading: false,
            ));
          } else {
            log('user email verified');
            // emit(const AuthStateLoggedOut(
            //   exception: null,
            //   isLoading: false,
            // ));
            emit(AuthStateLoggedIn(
              user: user,
              isLoading: false,
            ));
          }
        } on Exception catch (e) {
          emit(AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ));
        }
      },
    );

    //logout event
    on<AuthEventLogout>(
      (event, emit) async {
        try {
          await provider.logOut();
          emit(const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ));
        } on Exception catch (e) {
          emit(AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ));
        }
      },
    );

    on<AuthEventShouldRegister>(
      (event, emit) {
        emit(const AuthStateRegistering(
          exception: null,
          isLoading: false,
        ));
      },
    );

    on<AuthEventForgotPassword>(
      (event, emit) async {
        emit(const AuthStateForgotPassword(
          isLoading: false,
          hasSentEmail: false,
          exception: null,
        ));
        final email = event.email;
        if (email == null) {
          return;
        }
        emit(const AuthStateForgotPassword(
          isLoading: true,
          hasSentEmail: false,
          exception: null,
        ));
        bool didSentEmail;
        Exception? exception;
        try {
          await provider.sendPasswordReset(toEmail: email);
          didSentEmail = true;
          exception = null;
        } on Exception catch (e) {
          didSentEmail = false;
          exception = e;
        }
        emit(AuthStateForgotPassword(
          isLoading: false,
          hasSentEmail: didSentEmail,
          exception: exception,
        ));
      },
    );
  }
}
