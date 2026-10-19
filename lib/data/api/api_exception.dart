/// Thrown when an API request fails; [message] is user-presentable.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
