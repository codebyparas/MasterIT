// login exceptions
class UserNotFoundAuthException implements Exception {}
class InvalidCredentialsAuthException implements Exception {}

// register exceptions
class EmailAlreadyInUseAuthException implements Exception {}
class WeakPasswordAuthException implements Exception {}
class InvalidEmailAuthException implements Exception {}

// generic exceptions
class GenericAuthException implements Exception {}
class UserNotLoggedInAuthException implements Exception {}