class ApiResponse<T> {
  const ApiResponse({required this.data, this.timestamp});

  final T data;
  final DateTime? timestamp;

  factory ApiResponse.fromJson(
    Map<String, Object?> json,
    T Function(Object? value) decode,
  ) {
    if (!json.containsKey('data')) {
      throw const FormatException('API response is missing data');
    }
    final rawTimestamp = json['timestamp'];
    return ApiResponse<T>(
      data: decode(json['data']),
      timestamp: rawTimestamp is String
          ? DateTime.tryParse(rawTimestamp)
          : null,
    );
  }
}
