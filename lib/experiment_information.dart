class ExperimentInformation {
  ExperimentInformation(this.experimentID, this.experimentName, this.experimentDescription, this.currentVariant, this.variants);

  final String experimentID;
  final String experimentName;
  final String experimentDescription;
  final String currentVariant;
  final Map<String, Map<String, dynamic>> variants;

  static ExperimentInformation fromJson(dynamic json) {
    Map<String, Map<String, dynamic>> variantsMap = {};
    Map<Object?, Object?> variants = json['variants'] ?? {};
    for (var item in variants.keys)
    {
      Map<String, dynamic> valueMap = {};
      Map<Object?, Object?> values = variants[item] as Map<Object?, Object?>;
      for (var key in values.keys)
      {
        valueMap[key.toString()] = variants[key];
      }
      variantsMap[item.toString()] = valueMap;
    }
    return ExperimentInformation(json['experimentID'] ?? "", json['experimentName'] ?? "", json['experimentDescription'] ?? "", json['currentVariant'] ?? "", variantsMap);
  }
}