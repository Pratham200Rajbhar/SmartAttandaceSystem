
library;

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.31.239:8000/api/v1',
  // defaultValue: 'http://10.0.2.2:8000/api/v1',
);

const String kHiveBoxProfile = 'sas_profile';
const String kHiveBoxOfflineQueue = 'sas_offline_queue';
const String kHiveBoxNotifications = 'sas_notifications';

const String kSecureKeyJwt = 'sas_jwt_token';
const String kSecureKeyDeviceUuid = 'sas_device_uuid';
const String kSecureKeyUserRole = 'sas_user_role';

const int kConnectTimeout = 15000;
const int kReceiveTimeout = 15000;

const Duration kSessionPollMinInterval = Duration(seconds: 15);
const Duration kSessionPollMaxInterval = Duration(seconds: 60);

const int kMaxImageSizeBytes = 5 * 1024 * 1024;

const double kMinGpsAccuracyMeters = 60.0;
const double kGeofenceGraceMeters = 10.0;

const int kGpsRetryAttempts = 3;
const int kGpsTimeoutSeconds = 45;

const int kGpsAveragingSamples = 5;

const Duration kOfflineSyncRetryInterval = Duration(seconds: 15);

const Duration kOfflinePayloadMaxAge = Duration(hours: 2);

const String kUniversityEmailDomain = String.fromEnvironment(
  'UNIVERSITY_EMAIL_DOMAIN',
  defaultValue: '',
);
