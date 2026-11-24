import 'dart:convert';
import 'package:http/http.dart' as http;

class DumkClient {
  DumkClient(this.client);
  final http.Client client;
  static const host = 'api.muftyat.kz';

  Future<Object?> fetchCities() => _get(Uri.https(host, '/cities/'));
  Future<Object?> fetchYear(int year, String latitude, String longitude) {
    final lat = double.tryParse(latitude), lon = double.tryParse(longitude);
    if (year < 1900 ||
        year > 2200 ||
        lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      throw ArgumentError('Invalid year or coordinates');
    }
    return _get(Uri.https(host, '/prayer-times/$year/$latitude/$longitude'));
  }

  Future<Object?> _get(Uri uri) async {
    final request = http.Request('GET', uri)..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200)
      throw StateError('DUMK HTTP ${response.statusCode}');
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 12),
    )) {
      bytes.addAll(chunk);
      if (bytes.length > 4 * 1024 * 1024)
        throw const FormatException('Response too large');
    }
    return jsonDecode(utf8.decode(bytes));
  }
}
