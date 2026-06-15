/// Build identity constants for RC verification.
/// Testers can confirm they are running the correct build via StartScreen footer.
class BuildInfo {
  static const appVersion = '0.4.0-alpha';
  static const buildChannel = 'RC2';
  static const commitSha = '0ff3c01'; // previous commit — this is the best we can do pre-commit
  static const runtimeStorage = r'%APPDATA%\ScopeWorks\DeoReoNem';
}
