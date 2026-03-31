import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkdrop_app/model/user.dart';
import 'package:linkdrop_app/pages/home_page.dart';
import 'package:linkdrop_app/pages/splash_page.dart';
import 'package:linkdrop_app/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({
    required bool isAuthenticated,
    bool isLoading = false,
  })  : _isAuthenticated = isAuthenticated,
        _isLoading = isLoading;

  final bool _isAuthenticated;
  final bool _isLoading;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => null;

  @override
  AuthState get state => AuthState(
        isLoading: _isLoading,
        isAuthenticated: _isAuthenticated,
      );

  @override
  User? get user => null;

  @override
  void clearError() {}

  @override
  Future<void> clearCredentials() async {}

  @override
  Future<String?> getSavedPassword() async => null;

  @override
  Future<String?> getSavedUsername() async => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> login(String username, String password) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshUser() async {}

  @override
  Future<bool> register(String username, String password, {String? inviteCode}) async => true;

  @override
  Future<void> saveCredentials(String username, String password) async {}
}

class FakeLoginPage extends StatelessWidget {
  const FakeLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('mock-login-success'),
        ),
      ),
    );
  }
}

class FakeHomePage extends StatelessWidget {
  const FakeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('fake-home'),
      ),
    );
  }
}

void main() {
  testWidgets('unauthenticated startup navigates to home after login succeeds', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: FakeAuthProvider(isAuthenticated: false),
        child: MaterialApp(
          home: SplashPage(
            loginPageBuilder: (context) => const FakeLoginPage(),
            homePageBuilder: (context, initialTab, appStart) => const FakeHomePage(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('mock-login-success'), findsOneWidget);

    await tester.tap(find.text('mock-login-success'));
    await tester.pumpAndSettle();

    expect(find.text('fake-home'), findsOneWidget);
    expect(find.byType(FakeLoginPage), findsNothing);
  });
}