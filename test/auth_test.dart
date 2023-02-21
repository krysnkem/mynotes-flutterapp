import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock authentication', () {
    final provider = MockAuthProvider();
    test(
      'Should not be initialized',
      () {
        expect(provider.isInitialized, false);
      },
    );

    test(
      'Cannot log out if not initialzed',
      () async {
        expect(
            provider.logOut(),
            throwsA(
              const TypeMatcher<NotInitializedException>(),
            ));
      },
    );

    test(
      'Should be able to be initalized',
      () async {
        await provider.initialze();
        expect(provider.isInitialized, true);
      },
    );

    test(
      'User should be null',
      () {
        expect(provider.currentUser, null);
      },
    );

    test(
      'Should be able to initialize in less than 2 seconds',
      () async {
        await provider.initialze();
        expect(provider.isInitialized, true);
      },
      timeout: const Timeout(
        Duration(seconds: 2),
      ),
    );

    test('Create user should delegate to login', () async {
      final badEmailUser = provider.createUser(
        email: 'foobar@gmail.com',
        password: 'password123*',
      );
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );

      final badPasswordUser = provider.createUser(
        email: 'user@gmail.com',
        password: '12345',
      );
      expect(badPasswordUser,
          throwsA( isA<WrongPasswordAuthException>()));
      final user = await provider.createUser(
        email: 'foo',
        password: "password",
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('Login user should be able to get verified', () async {
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to log out and login again', () async {
      await provider.logOut();
      await provider.login(email: "email", password: "password");
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  bool _initialized = false;
  bool get isInitialized => _initialized;
  AuthUser? _user;
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!_initialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return login(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialze() async {
    await Future.delayed(const Duration(seconds: 1));
    _initialized = true;
  }

  @override
  Future<void> logOut() async {
    if (!_initialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user == null;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    if (!_initialized) throw NotInitializedException();
    if (email == 'foobar@gmail.com') throw UserNotFoundAuthException();
    if (password == '12345') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_initialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    const user = AuthUser(isEmailVerified: true);
    _user = user;
  }
}

void throwException() => throw WrongPasswordAuthException();
