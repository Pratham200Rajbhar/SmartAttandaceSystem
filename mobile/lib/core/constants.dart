// Centralized application constants.
// All environment-specific values are configured here for single-source modification.
library;

// API base URL — defaults to Android emulator localhost redirect.
/// Override via build-time config for staging/production.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.31.18:8000/api/v1',
);

/// Hive box names for structured local storage.
const String kHiveBoxProfile = 'sas_profile';
const String kHiveBoxOfflineQueue = 'sas_offline_queue';
const String kHiveBoxNotifications = 'sas_notifications';

/// Secure storage keys for sensitive data.
const String kSecureKeyJwt = 'sas_jwt_token';
const String kSecureKeyDeviceUuid = 'sas_device_uuid';
const String kSecureKeyUserRole = 'sas_user_role';

/// Network timeouts (milliseconds).
const int kConnectTimeout = 15000;
const int kReceiveTimeout = 15000;

/// Session polling intervals with exponential backoff.
const Duration kSessionPollMinInterval = Duration(seconds: 15);
const Duration kSessionPollMaxInterval = Duration(seconds: 60);

/// Maximum image upload size (5 MB).
const int kMaxImageSizeBytes = 5 * 1024 * 1024;

/// GPS accuracy requirements.
const double kMinGpsAccuracyMeters = 50.0;

/// Offline sync retry interval.
const Duration kOfflineSyncRetryInterval = Duration(seconds: 15);

/// Maximum age for offline payloads before they are discarded as expired.
const Duration kOfflinePayloadMaxAge = Duration(hours: 2);

/// University email domain for login validation.
/// Override via build-time config for different institutions.
const String kUniversityEmailDomain = String.fromEnvironment(
  'UNIVERSITY_EMAIL_DOMAIN',
  defaultValue: '',
);
