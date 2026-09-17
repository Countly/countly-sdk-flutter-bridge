abstract class Consent {
  /// Give consent for the given features.
  /// [List<String> consents]: feature names, see [CountlyConsent] for the accepted values
  Future<void> giveConsent(List<String> consents);

  /// Remove consent for the given features.
  /// [List<String> consents]: feature names, see [CountlyConsent] for the accepted values
  Future<void> removeConsent(List<String> consents);

  /// Give consent for every feature.
  Future<void> giveAllConsent();

  /// Remove consent for every feature.
  Future<void> removeAllConsent();
}
