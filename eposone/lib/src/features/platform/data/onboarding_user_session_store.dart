import 'package:shared_preferences/shared_preferences.dart';

/// Persiste User Bearer del asistente (separado del Device Bearer).
class OnboardingUserSessionStore {
  static const _tokenKey = 'en1_onboarding_user_bearer_v1';
  static const _urlKey = 'en1_onboarding_api_url_v1';
  static const _emailKey = 'en1_onboarding_email_v1';

  static Future<void> save({
    required String apiBaseUrl,
    required String accessToken,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, apiBaseUrl.trim());
    await prefs.setString(_tokenKey, accessToken);
    if (email != null) {
      await prefs.setString(_emailKey, email.trim());
    }
  }

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  static Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_urlKey);
    await prefs.remove(_emailKey);
  }
}
