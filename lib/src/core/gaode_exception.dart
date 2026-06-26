class GaodeException implements Exception {
  const GaodeException(this.message, {this.code, this.platformCode});

  final String message;
  final int? code;
  final String? platformCode;

  @override
  String toString() =>
      'GaodeException(code: $code, platformCode: $platformCode, message: $message)';
}
