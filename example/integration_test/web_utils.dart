import 'dart:html';

/// Clears localStorage on web platforms.
void clearWebLocalStorage() {
  window.localStorage.clear();
}

/// Writes a device ID into the Web SDK's storage as an earlier session would have left it, so a
/// following init has a stored device ID to find. Keys are namespaced by app key.
/// [String appKey] - the app key the instance is initialized with
/// [String deviceID] - the device ID to store
void seedWebDeviceID(String appKey, String deviceID) {
  window.localStorage['$appKey/cly_id'] = deviceID;
  window.localStorage['$appKey/cly_id_type'] = '0'; // 0 is the Web SDK's DEVELOPER_SUPPLIED type
}
