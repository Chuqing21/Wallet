// ignore_for_file: camel_case_types
//login exception

class UserNotFoundAuthException implements Exception {}

class WrongPasswordAuthException implements Exception {}

//register exception

class WeakPasswordAuthException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailException implements Exception {}

//generic exceptions

class GenericAuthException implements Exception {}

class UserNotLoggingAuthException implements Exception {}
