// Authentication state machine enum.
// Drives router guards and top-level UI branching.
enum AuthStatus {
  /// Initial state: checking stored JWT validity.
  loading,

  /// Valid JWT + face registered → full access.
  authenticated,

  /// No valid JWT → must login.
  unauthenticated,

  /// Valid JWT but face_embedding is null → lock on face registration.
  registrationRequired,
}
