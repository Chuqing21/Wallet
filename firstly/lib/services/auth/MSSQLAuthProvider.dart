import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'auth_user.dart';
import 'auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:shared_preferences/shared_preferences.dart';

class MSSQLAuthProvider implements AuthProvider {
  final String baseUrl = "http://10.0.2.2:3000/api";

  //final String baseUrl = "http://127.0.0.1:3000/api";

  AuthUser? _currentUser;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw GenericAuthException();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      devtools
          .log('Login API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        _currentUser = AuthUser(
          accountID: responseData['id'],
          email: email,
        );

        await _saveUserToPreferences(_currentUser!);
        return _currentUser!;
      } else if (response.statusCode == 404) {
        throw UserNotFoundAuthException();
      } else if (response.statusCode == 401) {
        throw WrongPasswordAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log(email);
      devtools.log('Login Error: $e');
      throw GenericAuthException();
    }
  }

  Future<void> _saveUserToPreferences(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accountID', user.accountID);
    await prefs.setString('email', user.email);
// Assuming user.id is the accountID
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      devtools.log(
          'Register API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _currentUser = AuthUser(
          accountID: responseData['id'],
          email: email,
        );
        await _saveUserToPreferences(_currentUser!);
        return _currentUser!;
      } else if (response.statusCode == 400) {
        throw EmailAlreadyInUseAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Register Error: $e');
      throw GenericAuthException();
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _clearUserFromPreferences();
  }

  Future<void> _clearUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<void> initialize() async {
    _currentUser = await _getUserFromPreferences();
  }

  Future<AuthUser?> _getUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final accountID = prefs.getInt('accountID');
    final email = prefs.getString('email');

    if (accountID != null  && email != null) {
      return AuthUser(
        accountID: accountID,
        email: email,
      );
    }
    return null;
  }
}
