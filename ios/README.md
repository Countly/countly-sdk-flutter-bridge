### Initializing or Updating the iOS SDK

The iOS SDK version is managed through `scripts/config/sdk_versions.txt`.
Run the sync script to initialize, update, or switch all SDK versions including iOS:

```bash
dart run scripts/sync_sdk_versions.dart
```

#### Changing the iOS SDK Version

Update `ios_sdk_version` in `scripts/config/sdk_versions.txt`, then run `dart run scripts/sync_sdk_versions.dart`.
The Countly iOS SDK is included as a Git submodule and will be checked out at the specified tag.
