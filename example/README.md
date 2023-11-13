# Countly Flutter Example App

This example app demonstrates most of the features the SDK offers.
You can quickly check the usage of features you are interested in.
It is possible that the app contains legacy code for the archival purposes.
So it is good practice to check the SDK [documentation](https://support.count.ly/hc/en-us/articles/360037944212).

## Usage
Make sure that Flutter is installed  functioning in your system by running:

```bash
flutter doctor
```

If you did not get any errors you can run the app by installing the repo:

```bash
git clone https://github.com/Countly/countly-sdk-flutter-bridge.git
cd countly-sdk-flutter-bridge/example
flutter pub get
```

Then you should change the SERVER_URL and APP_KEY values in 'config_object.dart' to values that you get from your Countly server. 

At this point if you are using Mac you would also need to do the following:

```bash
cd ios
pod install
```

Next you can run the app in an emulator/simulator or a real device by:

```bash
flutter run
```

### Explanation of the Content
The main content of the application is in 'lib' folder. Content here includes:
- main.dart (entry point to the app)
- page_*.dart (each page corresponding a feature)
- config_object.dart (manages SDK configuration)
- style.dart (for the app theme and styling)
- helpers.dart (some utility functions and classes)

## Fixing Platform Issues
If have you encountered a problem where you could not run the App regardless of following this guide the fastest way to proceed is by creating a fresh app and copying only the core files over.

Simply create a new Flutter project at a desired location:

```bash
flutter create new_project
cd new_project
```

You should first check if this project builds and run by:

```bash
flutter pub get
# for Mac also:
# cd ios
# pod install
flutter run
```

If it is working then you should copy and paste the 'lib' folder over to this new location and run:

```bash
flutter pub add countly_flutter
# for Mac also:
# cd ios
# pod install
flutter run
```

Now the application should be working. If it is still giving some errors/warnings those should be approached on case by case basis depending on the message (like missing assets and such).
