abstract class Sessions {
  Future<void> beginSession();
  Future<void> updateSession();
  Future<void> endSession();
}