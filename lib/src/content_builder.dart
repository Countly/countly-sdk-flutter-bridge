//indicates the content status
enum ContentStatus { completed, closed}

typedef ContentCallback = void Function(ContentStatus contentStatus, Map<String, dynamic> contentData);

abstract class ContentBuilder {
  /// This is an experimental feature and it can have breaking changes
  //  Opt in user for the content fetching and updates
  Future<void>  enterContentZone();

  /// This is an experimental feature and it can have breaking changes
  //  Opt out user for the content fetching and updates
  Future<void>  exitContentZone();
}