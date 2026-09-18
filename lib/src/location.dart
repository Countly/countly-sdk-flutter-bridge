abstract class Location {
  /// Set the user's location. Every parameter is optional, but at least one has to be given.
  /// [String? countryCode]: ISO country code of the user's country
  /// [String? city]: name of the user's city
  /// [String? gpsCoordinates]: comma separated latitude and longitude, for example "56.42345,123.45325"
  /// [String? ipAddress]: the user's IP address
  Future<void> setLocation({String? countryCode, String? city, String? gpsCoordinates, String? ipAddress});

  /// Stop reporting the user's location, and clear what was reported.
  Future<void> disableLocation();
}
