/// Central configuration for API endpoints
/// Read from environment variables or use defaults
class ApiConfig {
  /// API base URL - read from environment variable or use sensible defaults
  ///
  /// Environment variable: API_BASE_URL
  /// Default: http://localhost:8000 (for local development)
  ///
  /// Common configurations:
  /// - Local development: http://localhost:8000
  /// - Local via hotspot: http://192.168.18.40:8000
  /// - Production (Fly.io): https://spellbackend.fly.dev
  /// - Production (Render): https://spellbackend.onrender.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/',
  );
}
