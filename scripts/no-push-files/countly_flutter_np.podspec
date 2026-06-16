#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name = 'countly_flutter_np'
  s.version = '26.1.0'
  s.summary = 'Countly is an innovative, real-time, open source mobile analytics platform.'
  s.homepage = 'https://github.com/Countly/countly-sdk-flutter-bridge'
  s.social_media_url = 'https://twitter.com/gocountly'
  s.author = {'Countly' => 'hello@count.ly'}
  s.source = { :path => '.' }
  # Sources live in the Swift Package Manager layout; CocoaPods and SwiftPM share the same files.
  s.source_files = 'countly_flutter_np/Sources/countly_flutter_np/**/*.{h,m,swift}'
  s.public_header_files = 'countly_flutter_np/Sources/countly_flutter_np/include/countly_flutter_np/CountlyFlutterPlugin.h'
  s.resource_bundles = { 'countly_flutter_np_privacy' => ['countly_flutter_np/Sources/countly_flutter_np/countly-sdk-ios/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.swift_version = '5.0'
  s.ios.deployment_target = '10.0'
  s.static_framework = true
end

