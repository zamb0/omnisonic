import 'package:equatable/equatable.dart';
import 'server_status.dart';

class MusicServer extends Equatable {
  const MusicServer({
    required this.id,
    required this.name,
    required this.url,
    required this.username,
    required this.status,
    required this.createdAt,
    this.lastSync,
    this.apiVersion,
    this.serverVersion,
    this.errorMessage,
  });

  final String id;
  final String name;
  final String url;
  final String username;
  final ServerStatus status;
  final DateTime createdAt;
  final DateTime? lastSync;
  final String? apiVersion;
  final String? serverVersion;
  final String? errorMessage;

  /// Validates that the server has all required fields
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        url.isNotEmpty &&
        username.isNotEmpty &&
        _isValidUrl(url);
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Returns true if the server is available for operations
  bool get isAvailable => status.isAvailable;

  /// Returns true if the server is currently connecting
  bool get isConnecting => status.isConnecting;

  /// Returns true if the server has an error
  bool get hasError => status.hasError;

  /// Returns the base URL for API calls
  String get baseUrl {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  /// Returns the API endpoint URL
  String get apiUrl => '$baseUrl/rest';

  /// Creates a copy of this server with updated fields
  MusicServer copyWith({
    String? id,
    String? name,
    String? url,
    String? username,
    ServerStatus? status,
    DateTime? createdAt,
    DateTime? lastSync,
    String? apiVersion,
    String? serverVersion,
    String? errorMessage,
  }) {
    return MusicServer(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      username: username ?? this.username,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastSync: lastSync ?? this.lastSync,
      apiVersion: apiVersion ?? this.apiVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    username,
    status,
    createdAt,
    lastSync,
    apiVersion,
    serverVersion,
    errorMessage,
  ];

  @override
  String toString() =>
      'MusicServer(id: $id, name: $name, url: $url, status: $status)';
}
