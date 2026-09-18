abstract class Attribution {
  /// Report the campaign the user came from, with the data your attribution provider gives you.
  /// [String campaignType]: the type of the campaign, "countly" for a Countly campaign
  /// [String campaignData]: the campaign data as a JSON string, for a Countly campaign an object with "cid" and optionally "cuid"
  Future<void> recordDirectAttribution(String campaignType, String campaignData);

  /// Report attribution identifiers the SDK can not read itself, such as the advertising ID.
  /// [Map<String, String> attributionValues]: identifiers keyed by [AttributionKey]
  Future<void> recordIndirectAttribution(Map<String, String> attributionValues);
}
