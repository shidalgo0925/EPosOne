import 'package:eposone/src/features/platform/data/provisioning_store.dart';
import 'package:eposone/src/features/settings/domain/entities/business_config.dart';

/// Credenciales EN1 para APIs de dispositivo (Orders, Cash Shift, Bootstrap).
///
/// El Device Token de [ProvisioningStore] es la fuente de verdad (Hito 1).
/// `BusinessConfig.en1ApiToken` solo se usa como fallback (p. ej. legacy / stub).
class En1DeviceCredentials {
  En1DeviceCredentials._();

  static Future<({String base, String token})> resolve({
    String? apiBaseUrl,
    String? accessToken,
    BusinessConfig? config,
  }) async {
    final provisioned = await ProvisioningStore.loadConfig();
    final base = (apiBaseUrl ??
            config?.en1ApiUrl ??
            provisioned?.apiBaseUrl ??
            '')
        .trim();

    final explicit = accessToken?.trim() ?? '';
    final device = provisioned?.accessToken.trim() ?? '';
    final fromConfig = config?.en1ApiToken?.trim() ?? '';

    // Preferencia: argumento explícito → Device Token provisionado → config UI.
    final token = explicit.isNotEmpty
        ? explicit
        : (device.isNotEmpty ? device : fromConfig);

    return (base: _normalizeBase(base), token: token);
  }

  /// Alinea BusinessConfig con el Device Token / URL del provisioning.
  static Future<BusinessConfig> alignBusinessConfig(BusinessConfig config) async {
    final provisioned = await ProvisioningStore.loadConfig();
    if (provisioned == null || !provisioned.isComplete) return config;

    final token = provisioned.accessToken.trim();
    final url = provisioned.apiBaseUrl.trim();
    final branch = provisioned.branchRef.trim();
    if (token.isEmpty && url.isEmpty) return config;

    final needsToken = token.isNotEmpty && config.en1ApiToken?.trim() != token;
    final needsUrl = url.isNotEmpty && config.en1ApiUrl?.trim() != url;
    final needsBranch =
        branch.isNotEmpty && (config.en1BranchId?.trim() ?? '').isEmpty;

    if (!needsToken && !needsUrl && !needsBranch) return config;

    return config
        .copyWith(
          en1ApiToken: needsToken ? token : config.en1ApiToken,
          en1ApiUrl: needsUrl ? url : config.en1ApiUrl,
          en1BranchId: needsBranch ? branch : config.en1BranchId,
          en1SyncEnabled: true,
        )
        .markAsModified();
  }

  static bool isInstallationIncomplete(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('installation_incomplete');
  }

  static String _normalizeBase(String url) {
    var b = url.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }
}
