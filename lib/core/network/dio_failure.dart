import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import '../errors/problem_details.dart';

/// Único lugar donde un [DioException] se convierte a [AppFailure].
AppFailure failureFromDioException(DioException error) {
  final Object? inner = error.error;
  if (inner is AppFailure) {
    return inner;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final Response<dynamic>? response = error.response;
      if (response == null) {
        return const NetworkFailure();
      }
      return failureFromProblemDetails(
        statusCode: response.statusCode ?? 0,
        body: response.data,
      );
    case DioExceptionType.cancel:
      return const UnknownFailure(detail: 'La solicitud fue cancelada.');
    case DioExceptionType.unknown:
      return const NetworkFailure();
  }
}
