// #define COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
#import "CountlyFlutterPlugin.h"
#import "Countly.h"
#import "CountlyCommon.h"
#import "CountlyConfig.h"
#import "CountlyDeviceInfo.h"
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
#import "CountlyFLPushNotifications.h"
#endif
#import "CountlyRemoteConfig.h"

#if DEBUG
#define COUNTLY_FLUTTER_LOG(fmt, ...) CountlyFlutterInternalLog(fmt, ##__VA_ARGS__)
#else
#define COUNTLY_FLUTTER_LOG(...)
#endif

@interface CountlyFeedbackWidget ()
+ (CountlyFeedbackWidget *)createWithDictionary:(NSDictionary *)dictionary;
@end

@interface CountlyPersistency ()
@property(nonatomic) NSMutableArray *queuedRequests;
@property(nonatomic) NSMutableArray *recordedEvents;
@end

@interface CountlyFlutterPlugin ()
@property(nonatomic, strong) FlutterMethodChannel *channel;
@property(nonatomic, weak) NSObject<FlutterPluginRegistrar> *registrar;
@end

BOOL BUILDING_WITH_PUSH_DISABLED = false;

CLYPushTestMode const CLYPushTestModeProduction = @"CLYPushTestModeProduction";

NSString *const kCountlyFlutterSDKVersion = @"26.1.1";
NSString *const kCountlyFlutterSDKName = @"dart-flutterb-ios";
NSString *const kCountlyFlutterSDKNameNoPush = @"dart-flutterbnp-ios";

NSMutableArray<CLYFeature> *countlyFeatures = nil;
NSArray<CountlyFeedbackWidget *> *feedbackWidgetList = nil;

NSString *const NAME_KEY = @"name";
NSString *const USERNAME_KEY = @"username";
NSString *const EMAIL_KEY = @"email";
NSString *const ORG_KEY = @"organization";
NSString *const PHONE_KEY = @"phone";
NSString *const PICTURE_KEY = @"picture";
NSString *const PICTURE_PATH_KEY = @"picturePath";
NSString *const GENDER_KEY = @"gender";
NSString *const BYEAR_KEY = @"byear";
NSString *const CUSTOM_KEY = @"custom";
NSString *const CountlyStarRatingConsent = @"star-rating";

@implementation CountlyFlutterPlugin

CountlyConfig *config = nil;
Boolean isInitialized = false;
NSMutableDictionary *networkRequest = nil;
// Channel for native callbacks: the first engine's, until an engine with UI initializes the SDK.
static FlutterMethodChannel *callbackChannel = nil;
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"countly_flutter" binaryMessenger:[registrar messenger]];
    CountlyFlutterPlugin *instance = [[CountlyFlutterPlugin alloc] init];
    instance.channel = channel;
    instance.registrar = registrar;
    if (callbackChannel == nil) {
        callbackChannel = channel;
    }
    [registrar addMethodCallDelegate:instance channel:channel];
}

/**
 * Stops sending native callbacks to this engine once it is torn down.
 */
- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    if (callbackChannel == self.channel) {
        callbackChannel = nil;
    }
}

/**
 * Makes this engine the target of native callbacks when no engine is, or when this engine shows the
 * app's UI, so a headless engine that calls init cannot take callbacks away from the UI.
 */
- (void)bindCallbackChannel {
    if (callbackChannel == nil || [self hasViewController]) {
        callbackChannel = self.channel;
    }
}

/**
 * Whether this plugin's engine is attached to a view controller. Headless engines, such as ones
 * started for background work, are not. Older Flutter versions do not expose the view controller.
 */
- (BOOL)hasViewController {
    NSObject<FlutterPluginRegistrar> *registrar = self.registrar;
    return [registrar respondsToSelector:@selector(viewController)] && [(NSObject *)registrar valueForKey:@"viewController"] != nil;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *commandString = call.arguments[@"data"];
    if (commandString == nil) {
        commandString = @"[]";
    }
    NSData *data = [commandString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSArray *command = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];

    if (config == nil) {
        config = CountlyConfig.new;
    }

    if ([@"init" isEqualToString:call.method]) {
        [self bindCallbackChannel];
        NSDictionary *_config = [command objectAtIndex:0];
        [self populateConfig:_config];
        config.internalLogLevel = CLYInternalLogLevelVerbose;
        CountlyCommon.sharedInstance.SDKName = BUILDING_WITH_PUSH_DISABLED ? kCountlyFlutterSDKNameNoPush : kCountlyFlutterSDKName;
        CountlyCommon.sharedInstance.SDKVersion = kCountlyFlutterSDKVersion;

        // should only be used for silent pushes if explicitly enabled
        // config.sendPushTokenAlways = YES;
#if (TARGET_OS_IOS)
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        if ([CountlyFLPushNotifications.sharedInstance enablePushNotifications]) {
            [self addCountlyFeature:CLYPushNotifications];
        }
#endif
#endif
        if (config.host && [config.host length] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
              isInitialized = true;
              [[Countly sharedInstance] startWithConfig:config];

#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
              [CountlyFLPushNotifications.sharedInstance recordPushActions];
#endif
            });
            result(@"initialized.");
        } else {
            result(@"initialization failed!");
        }

        // // config.deviceID = deviceID; doesn't work so applied at patch temporarly.
        // if(command.count == 3){
        //     deviceID = [command objectAtIndex:2];
        //     [Countly.sharedInstance setNewDeviceID:deviceID onServer:YES];   //replace and merge on server
        // }
    } else if ([@"isInitialized" isEqualToString:call.method]) {
        if (isInitialized) {
            result(@"true");
        } else {
            result(@"false");
        }
    } else if ([@"getRequestQueue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMutableArray *queuedRequests = [CountlyPersistency.sharedInstance queuedRequests];
          result(queuedRequests);
        });
    } else if ([@"getEventQueue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMutableArray *recordedEvents = [CountlyPersistency.sharedInstance recordedEvents];
          NSMutableArray *recordedEventsJSON = NSMutableArray.new;

          for (id event in recordedEvents.copy) {
              NSString *eventJson = [self toJSON:[event dictionaryRepresentation]];
              if (eventJson) {
                  [recordedEventsJSON addObject:eventJson];
              }
          }
          result(recordedEventsJSON);
        });
    } else if ([@"storeRequest" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *request = [command objectAtIndex:0];
          NSMutableArray *queuedRequests = [CountlyPersistency.sharedInstance queuedRequests];
          [queuedRequests addObject:request];
          [CountlyPersistency.sharedInstance saveToFile];
          result(@"stored request");
        });
    } else if ([@"addDirectRequest" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMutableDictionary *requestMap = [command objectAtIndex:0];
          [Countly.sharedInstance addDirectRequest:requestMap];
          result(@"added request to queue");
        });
    } else if ([@"setServerConfig" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSMutableDictionary *serverConfig = [command objectAtIndex:0];
          [NSUserDefaults.standardUserDefaults setObject:serverConfig forKey:@"kCountlyServerConfigPersistencyKey"];
          [NSUserDefaults.standardUserDefaults synchronize];
          result(@"setServerConfig: success");
        });
    } else if ([@"testOnNotification" isEqualToString:call.method]) {
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        NSArray *payloads = [command objectAtIndex:0];
        for (NSDictionary *payload in payloads) {
            [CountlyFLPushNotifications.sharedInstance onNotification:payload];
        }
#endif
        result(nil);
    } else if ([@"getServerConfig" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *storedConfig = [NSUserDefaults.standardUserDefaults objectForKey:@"kCountlyServerConfigPersistencyKey"];

          NSMutableDictionary *serverConfig = nil;
          if ([storedConfig isKindOfClass:[NSDictionary class]]) {
              serverConfig = [storedConfig mutableCopy];
          } else {
              serverConfig = [NSMutableDictionary new];
          }

          result(serverConfig);
        });
    } else if ([@"recordReservedEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSDictionary *segmentation;
          if ((int)command.count > 1) {
              segmentation = [command objectAtIndex:1];
          } else {
              segmentation = nil;
          }

          [[Countly sharedInstance] recordReservedEvent:key segmentation:segmentation];

          NSString *resultString = @"recordReservedEvent for: ";
          resultString = [resultString stringByAppendingString:key];
          result(resultString);
        });
    } else if ([@"recordEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSString *countString = [command objectAtIndex:1];
          int count = [countString intValue];
          NSString *sumString = [command objectAtIndex:2];
          double sum = [sumString doubleValue];
          NSString *durationString = [command objectAtIndex:3];
          int duration = [durationString intValue];
          NSDictionary *segmentation;
          if ((int)command.count > 4) {
              segmentation = [command objectAtIndex:4];
          } else {
              segmentation = nil;
          }

          [[Countly sharedInstance] recordEvent:key segmentation:segmentation count:count sum:sum duration:duration];

          NSString *resultString = @"recordEvent for: ";
          resultString = [resultString stringByAppendingString:key];
          result(resultString);
        });
    } else if ([@"setLoggingEnabled" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          BOOL boolean = [[command objectAtIndex:0] boolValue];
          config.enableDebug = boolean;
          result(@"setLoggingEnabled!");
        });

    } else if ([@"setuserdata" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *userData = [command objectAtIndex:0];

          [self setUserData:userData];

          [Countly.user save];
          result(@"setuserdata!");
        });

    } else if ([@"beginSession" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance beginSession];
          result(@"beginSession!");
        });

    } else if ([@"updateSession" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance updateSession];
          result(@"updateSession!");
        });

    } else if ([@"endSession" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance endSession];
          result(@"endSession!");
        });

    } else if ([@"manualSessionHandling" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          config.manualSessionHandling = YES;
          result(@"manualSessionHandling!");
        });

    } else if ([@"updateSessionPeriod" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          config.updateSessionPeriod = 15;
          result(@"updateSessionPeriod!");
        });

    } else if ([@"updateSessionInterval" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          @try {
              int sessionInterval = [[command objectAtIndex:0] intValue];
              config.updateSessionPeriod = sessionInterval;
              result(@"updateSessionInterval Success!");
          } @catch (NSException *exception) {
              NSString *errorMessage = [NSString stringWithFormat:@"Exception occurred at updateSessionInterval method: %@", exception];
              COUNTLY_FLUTTER_LOG(errorMessage);
              result(errorMessage);
          };
        });
    } else if ([@"eventSendThreshold" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          @try {
              int limit = [[command objectAtIndex:0] intValue];
              config.eventSendThreshold = limit;
              result(@"eventSendThreshold!");
          } @catch (NSException *exception) {
              NSString *errorMessage = [NSString stringWithFormat:@"Exception occurred at eventSendThreshold method: %@", exception];
              COUNTLY_FLUTTER_LOG(errorMessage);
              result(errorMessage);
          };
        });

    } else if ([@"storedRequestsLimit" isEqualToString:call.method]) {
        COUNTLY_FLUTTER_LOG(@"storedRequestsLimit is deprecated and has no effect, use 'setMaxRequestQueueSize' of CountlyConfig instead");
        result(@"storedRequestsLimit: deprecated, no effect");

    } else if ([@"getID" isEqualToString:call.method]) {
        // Countly.deviceID returns the ID URL-escaped for requests; Dart needs the ID as it was set.
        NSString *deviceId = CountlyDeviceInfo.sharedInstance.deviceID;
        result(deviceId);
    } else if ([@"getIDType" isEqualToString:call.method]) {
        CLYDeviceIDType deviceIDType = [Countly.sharedInstance deviceIDType];
        NSString *deviceIDTypeString = NULL;
        if ([deviceIDType isEqualToString:CLYDeviceIDTypeCustom]) {
            deviceIDTypeString = @"DS";
        } else if ([deviceIDType isEqualToString:CLYDeviceIDTypeIDFV]) {
            deviceIDTypeString = @"SG";
        } else if ([deviceIDType isEqualToString:CLYDeviceIDTypeTemporary]) {
            deviceIDTypeString = @"TID";
        } else {
            deviceIDTypeString = @"SG";
        }
        result(deviceIDTypeString);
    } else if ([@"setID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *newDeviceID = [command objectAtIndex:0];
          [Countly.sharedInstance setID:newDeviceID];
          result(@"setID success!");
        });
    } else if ([@"enableTemporaryIDMode" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance enableTemporaryDeviceIDMode];
          result(@"enableTemporaryIDMode success!");
        });
    } else if ([@"changeWithMerge" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *newDeviceID = [command objectAtIndex:0];
          [Countly.sharedInstance changeDeviceIDWithMerge:newDeviceID];
          result(@"changeWithMerge!");
        });

    } else if ([@"changeWithoutMerge" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *newDeviceID = [command objectAtIndex:0];
          [Countly.sharedInstance changeDeviceIDWithoutMerge:newDeviceID];
          result(@"changeWithoutMerge!");
        });

    } else if ([@"setHttpPostForced" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          BOOL boolean = [[command objectAtIndex:0] boolValue];
          config.alwaysUsePOST = boolean;
          result(@"setHttpPostForced!");
        });

    } else if ([@"enableParameterTamperingProtection" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *salt = [command objectAtIndex:0];
          config.secretSalt = salt;
          result(@"enableParameterTamperingProtection!");
        });

    } else if ([@"startEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *eventName = [command objectAtIndex:0];
          [Countly.sharedInstance startEvent:eventName];
          result(@"startEvent!");
        });

    } else if ([@"cancelEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *eventName = [command objectAtIndex:0];
          [Countly.sharedInstance cancelEvent:eventName];
          result(@"cancelEvent!");
        });

    } else if ([@"endEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSString *countString = [command objectAtIndex:1];
          int count = [countString intValue];
          NSString *sumString = [command objectAtIndex:2];
          double sum = [sumString doubleValue];
          NSDictionary *segmentation;
          if ((int)command.count > 3) {
              segmentation = [command objectAtIndex:3];
          } else {
              segmentation = nil;
          }
          [[Countly sharedInstance] endEvent:key segmentation:segmentation count:count sum:sum];
          NSString *resultString = @"endEvent for: ";
          resultString = [resultString stringByAppendingString:key];
          result(resultString);
        });
    } else if ([@"setLocationInit" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *countryCode = [command objectAtIndex:0];
          NSString *city = [command objectAtIndex:1];
          NSString *locationString = [command objectAtIndex:2];
          NSString *ipAddress = [command objectAtIndex:3];

          if (locationString != nil && ![locationString isEqualToString:@"null"] && [locationString containsString:@","]) {
              @try {
                  NSArray *locationArray = [locationString componentsSeparatedByString:@","];
                  NSString *latitudeString = [locationArray objectAtIndex:0];
                  NSString *longitudeString = [locationArray objectAtIndex:1];

                  double latitudeDouble = [latitudeString doubleValue];
                  double longitudeDouble = [longitudeString doubleValue];
                  config.location = (CLLocationCoordinate2D){latitudeDouble, longitudeDouble};
              } @catch (NSException *exception) {
                  COUNTLY_FLUTTER_LOG(@"[setLocationInit], Invalid location: %@", locationString);
              }
          }
          if (city != nil && ![city isEqualToString:@"null"]) {
              config.city = city;
          }
          if (countryCode != nil && ![countryCode isEqualToString:@"null"]) {
              config.ISOCountryCode = countryCode;
          }
          if (ipAddress != nil && ![ipAddress isEqualToString:@"null"]) {
              config.IP = ipAddress;
          }
          result(@"setLocationInit!");
        });

    } else if ([@"setLocation" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *latitudeString = [command objectAtIndex:0];
          NSString *longitudeString = [command objectAtIndex:1];

          if ([@"null" isEqualToString:latitudeString]) {
              latitudeString = nil;
          }
          if ([@"null" isEqualToString:longitudeString]) {
              longitudeString = nil;
          }

          if (latitudeString != nil && longitudeString != nil) {
              @try {
                  double latitudeDouble = [latitudeString doubleValue];
                  double longitudeDouble = [longitudeString doubleValue];
                  config.location = (CLLocationCoordinate2D){latitudeDouble, longitudeDouble};
              } @catch (NSException *exception) {
                  COUNTLY_FLUTTER_LOG(@"[setLocation], Invalid latitude or longitude.");
              }
          }
          result(@"setLocation!");
        });

    } else if ([@"setUserLocation" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *location = [command objectAtIndex:0];
          NSString *gpsCoordinate = location[@"gpsCoordinates"];
          CLLocationCoordinate2D locationCoordinate = [self getCoordinate:gpsCoordinate];

          NSString *city = location[@"city"];
          if (!city || [[NSNull null] isEqual:city] || !city.length) {
              city = nil;
          }

          NSString *countryCode = location[@"countryCode"];
          if (!countryCode || [[NSNull null] isEqual:countryCode] || !countryCode.length) {
              countryCode = nil;
          }

          NSString *ipAddress = location[@"ipAddress"];
          if (!ipAddress || [[NSNull null] isEqual:ipAddress] || !ipAddress.length) {
              ipAddress = nil;
          }

          [Countly.sharedInstance recordLocation:locationCoordinate city:city ISOCountryCode:countryCode IP:ipAddress];
          result(@"setUserLocation!");
        });

    } else if ([@"disableLocation" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance disableLocationInfo];
          result(@"disableLocation!");
        });

    } else if ([@"addCrashLog" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *record = [command objectAtIndex:0];
          [Countly.sharedInstance recordCrashLog:record];
          result(@"addCrashLog!");
        });

    } else if ([@"logException" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *exception = [command objectAtIndex:0];
          NSString *nonfatal = [command objectAtIndex:1];
          NSArray *nsException = [exception componentsSeparatedByString:@"\n"];

          NSMutableDictionary *segmentation = [[NSMutableDictionary alloc] init];

          for (int i = 2, il = (int)command.count; i < il; i += 2) {
              segmentation[[command objectAtIndex:i]] = [command objectAtIndex:i + 1];
          }

          NSException *myException = [NSException exceptionWithName:@"Exception" reason:exception userInfo:nil];

          BOOL isFatal = ![nonfatal boolValue];
          [Countly.sharedInstance recordException:myException isFatal:isFatal stackTrace:nsException segmentation:segmentation];
          result(@"logException!");
        });

    } else if ([@"disablePushNotifications" isEqualToString:call.method]) {
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        [CountlyFLPushNotifications.sharedInstance disablePushNotifications];
#endif
        result(@"disablePushNotifications!");
    } else if ([@"askForNotificationPermission" isEqualToString:call.method]) {
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        [CountlyFLPushNotifications.sharedInstance askForNotificationPermission];
#endif
        result(@"askForNotificationPermission!");
    } else if ([@"pushTokenType" isEqualToString:call.method]) {
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *tokenType = [command objectAtIndex:0];
          config.pushTestMode = CLYPushTestModeProduction;

          if ([tokenType isEqualToString:@"1"]) {
              config.pushTestMode = CLYPushTestModeDevelopment;
          } else if ([tokenType isEqualToString:@"2"]) {
              config.pushTestMode = CLYPushTestModeTestFlightOrAdHoc;
          }
        });
#endif
        result(@"pushTokenType!");
    } else if ([@"registerForNotification" isEqualToString:call.method]) {
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        COUNTLY_FLUTTER_LOG(@"registerForNotification");
        [CountlyFLPushNotifications.sharedInstance registerForNotification:result];
#endif
    } else if ([@"userData_setProperty" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];
          NSString *keyValue = [command objectAtIndex:1];

          [Countly.user set:keyName value:keyValue];
          [Countly.user save];

          result(@"userData_setProperty!");
        });

    } else if ([@"userData_increment" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];

          [Countly.user increment:keyName];
          [Countly.user save];

          result(@"userData_increment!");
        });

    } else if ([@"userData_incrementBy" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];
          NSString *keyValue = [command objectAtIndex:1];
          int keyValueInteger = [keyValue intValue];

          [Countly.user incrementBy:keyName value:[NSNumber numberWithInt:keyValueInteger]];
          [Countly.user save];

          result(@"userData_incrementBy!");
        });

    } else if ([@"userData_multiply" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];
          NSString *keyValue = [command objectAtIndex:1];
          int keyValueInteger = [keyValue intValue];

          [Countly.user multiply:keyName value:[NSNumber numberWithInt:keyValueInteger]];
          [Countly.user save];

          result(@"userData_multiply!");
        });

    } else if ([@"userData_saveMax" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];
          NSString *keyValue = [command objectAtIndex:1];
          int keyValueInteger = [keyValue intValue];

          [Countly.user max:keyName value:[NSNumber numberWithInt:keyValueInteger]];
          [Countly.user save];
          result(@"userData_saveMax!");
        });

    } else if ([@"userData_saveMin" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];
          NSString *keyValue = [command objectAtIndex:1];
          int keyValueInteger = [keyValue intValue];

          [Countly.user min:keyName value:[NSNumber numberWithInt:keyValueInteger]];
          [Countly.user save];

          result(@"userData_saveMin!");
        });

    } else if ([@"userData_setOnce" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *keyName = [command objectAtIndex:0];
          NSString *keyValue = [command objectAtIndex:1];

          [Countly.user setOnce:keyName value:keyValue];
          [Countly.user save];

          result(@"userData_setOnce!");
        });

    } else if ([@"userData_pushUniqueValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *type = [command objectAtIndex:0];
          NSString *pushUniqueValueString = [command objectAtIndex:1];

          [Countly.user pushUnique:type value:pushUniqueValueString];
          [Countly.user save];

          result(@"userData_pushUniqueValue!");
        });

    } else if ([@"userData_pushValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *type = [command objectAtIndex:0];
          NSString *pushValue = [command objectAtIndex:1];

          [Countly.user push:type value:pushValue];
          [Countly.user save];

          result(@"userData_pushValue!");
        });

    } else if ([@"userData_pullValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *type = [command objectAtIndex:0];
          NSString *pullValue = [command objectAtIndex:1];

          [Countly.user pull:type value:pullValue];
          [Countly.user save];

          result(@"userData_pullValue!");
        });

    } else if ([@"userProfile_setProperties" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *userProperties = [command objectAtIndex:0];
          if ([userProperties isKindOfClass:NSDictionary.class]) {
              [Countly.sharedInstance.userProfile setProperties:userProperties];
          }
          result(nil);
        });

    } else if ([@"userProfile_setProperty" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          id value = [command objectAtIndex:1];

          [Countly.sharedInstance.userProfile setProperty:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_increment" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];

          [Countly.user increment:key];
          result(nil);
        });

    } else if ([@"userProfile_incrementBy" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSNumber *value = [command objectAtIndex:1];

          [Countly.user incrementBy:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_multiply" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSNumber *value = [command objectAtIndex:1];

          [Countly.user multiply:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_saveMax" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSNumber *value = [command objectAtIndex:1];

          [Countly.user max:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_saveMin" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSNumber *value = [command objectAtIndex:1];

          [Countly.user min:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_setOnce" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSString *value = [command objectAtIndex:1];

          [Countly.user setOnce:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_pushUnique" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSString *value = [command objectAtIndex:1];

          [Countly.user pushUnique:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_push" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSString *value = [command objectAtIndex:1];

          [Countly.user push:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_pull" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *key = [command objectAtIndex:0];
          NSString *value = [command objectAtIndex:1];

          [Countly.user pull:key value:value];
          result(nil);
        });

    } else if ([@"userProfile_save" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.user save];
          result(nil);
        });

    } else if ([@"userProfile_clear" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.user clearUserDetails];
          result(nil);
        });

        // setRequiresConsent
    } else if ([@"setRequiresConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          BOOL consentFlag = [[command objectAtIndex:0] boolValue];
          config.requiresConsent = consentFlag;
          result(@"setRequiresConsent!");
        });

    } else if ([@"giveConsentInit" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          config.consents = [self iOSConsentsFrom:command];
          result(@"giveConsentInit!");
        });

    } else if ([@"giveConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance giveConsentForFeatures:[self iOSConsentsFrom:command]];
          result(@"giveConsent!");
        });

    } else if ([@"removeConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance cancelConsentForFeatures:[self iOSConsentsFrom:command]];
          result(@"removeConsent!");
        });

    } else if ([@"giveAllConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance giveAllConsents];
          result(@"giveAllConsent!");
        });
    } else if ([@"removeAllConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance cancelConsentForAllFeatures];
          result(@"removeAllConsent!");
        });
    } else if ([@"setOptionalParametersForInitialization" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *city = [command objectAtIndex:0];
          NSString *country = [command objectAtIndex:1];

          NSString *latitudeString = [command objectAtIndex:2];
          NSString *longitudeString = [command objectAtIndex:3];
          NSString *ipAddress = [command objectAtIndex:4];

          if ([@"null" isEqualToString:city]) {
              city = nil;
          }
          if ([@"null" isEqualToString:country]) {
              country = nil;
          }
          if ([@"null" isEqualToString:latitudeString]) {
              latitudeString = nil;
          }
          if ([@"null" isEqualToString:longitudeString]) {
              longitudeString = nil;
          }
          if ([@"null" isEqualToString:ipAddress]) {
              ipAddress = nil;
          }
          CLLocationCoordinate2D location = kCLLocationCoordinate2DInvalid;
          if (latitudeString != nil && longitudeString != nil) {
              @try {
                  double latitudeDouble = [latitudeString doubleValue];
                  double longitudeDouble = [longitudeString doubleValue];

                  location = (CLLocationCoordinate2D){latitudeDouble, longitudeDouble};
              } @catch (NSException *exception) {
                  COUNTLY_FLUTTER_LOG(@"[setOptionalParametersForInitialization], Invalid latitude or longitude.");
              }
          }
          [Countly.sharedInstance recordLocation:location city:city ISOCountryCode:country IP:ipAddress];
          result(@"setOptionalParametersForInitialization!");
        });

    } else if ([@"remoteConfigDownloadValues" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSNumber *callbackID = [command objectAtIndex:0];
          if ([self rejectRemoteConfigDownloadIfUnavailable:callbackID]) {
              result(@"success");
              return;
          }
          [Countly.sharedInstance.remoteConfig downloadKeys:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error, BOOL fullValueUpdate, NSDictionary<NSString *, CountlyRCData *> *_Nonnull downloadedValues) {
            [self remoteConfigDownloadCallback:callbackID response:response fullValueUpdate:fullValueUpdate error:error downloadedValues:downloadedValues];
          }];

          result(@"success");
        });
    } else if ([@"remoteConfigDownloadSpecificValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSNumber *callbackID = [command objectAtIndex:0];
          NSArray *keys = [command objectAtIndex:1];
          if ([self rejectRemoteConfigDownloadIfUnavailable:callbackID]) {
              result(@"Success!");
              return;
          }
          [Countly.sharedInstance.remoteConfig downloadSpecificKeys:keys
                                                  completionHandler:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error, BOOL fullValueUpdate, NSDictionary<NSString *, CountlyRCData *> *_Nonnull downloadedValues) {
                                                    [self remoteConfigDownloadCallback:callbackID response:response fullValueUpdate:fullValueUpdate error:error downloadedValues:downloadedValues];
                                                  }];
          result(@"Success!");
        });

    } else if ([@"remoteConfigDownloadOmittingValues" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSNumber *callbackID = [command objectAtIndex:0];
          NSArray *omitKeys = [command objectAtIndex:1];
          if ([self rejectRemoteConfigDownloadIfUnavailable:callbackID]) {
              result(@"Success!");
              return;
          }

          [Countly.sharedInstance.remoteConfig downloadOmittingKeys:omitKeys
                                                  completionHandler:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error, BOOL fullValueUpdate, NSDictionary<NSString *, CountlyRCData *> *_Nonnull downloadedValues) {
                                                    [self remoteConfigDownloadCallback:callbackID response:response fullValueUpdate:fullValueUpdate error:error downloadedValues:downloadedValues];
                                                  }];
          result(@"Success!");
        });

    } else if ([@"remoteConfigGetAllValues" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary<NSString *, CountlyRCData *> *allRCDataValues = [Countly.sharedInstance.remoteConfig getAllValues];
          NSDictionary *rCValues = [self getRCValues:allRCDataValues];
          result(rCValues);
        });

    } else if ([@"remoteConfigGetValue" isEqualToString:call.method]) {
        NSString *key = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          CountlyRCData *rcData = [Countly.sharedInstance.remoteConfig getValue:key];
          NSDictionary *rcDataMap = [self rcDataToMap:rcData];
          result(rcDataMap);
        });

    } else if ([@"remoteConfigGetValueAndEnroll" isEqualToString:call.method]) {
        NSString *key = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          CountlyRCData *rcData = [Countly.sharedInstance.remoteConfig getValueAndEnroll:key];
          NSDictionary *rcDataMap = [self rcDataToMap:rcData];
          result(rcDataMap);
        });

    } else if ([@"remoteConfigGetAllValuesAndEnroll" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary<NSString *, CountlyRCData *> *allRCDataValues = [Countly.sharedInstance.remoteConfig getAllValuesAndEnroll];
          NSDictionary *rCValues = [self getRCValues:allRCDataValues];
          result(rCValues);
        });

    } else if ([@"remoteConfigClearAllValues" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.remoteConfig clearAll];
          result(@"Success!");
        });

    } else if ([@"remoteConfigEnrollIntoABTestsForKeys" isEqualToString:call.method]) {
        NSArray *keys = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.remoteConfig enrollIntoABTestsForKeys:keys];
          result(@"Success!");
        });

    } else if ([@"remoteConfigExitABTestsForKeys" isEqualToString:call.method]) {
        NSArray *keys = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.remoteConfig exitABTestsForKeys:keys];
          result(@"Success!");
        });

    } else if ([@"remoteConfigTestingGetVariantsForKey" isEqualToString:call.method]) {
        NSString *key = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          NSArray *variants = [Countly.sharedInstance.remoteConfig testingGetVariantsForKey:key];
          result(variants);
        });

    } else if ([@"remoteConfigTestingGetAllVariants" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *allVariants = [Countly.sharedInstance.remoteConfig testingGetAllVariants];
          result(allVariants);
        });

    } else if ([@"remoteConfigTestingDownloadVariantInformation" isEqualToString:call.method]) {
        NSNumber *callbackID = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.remoteConfig testingDownloadVariantInformation:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error) {
            [self remoteConfigVariantCallback:callbackID response:response error:error];
          }];
          result(@"Success!");
        });

    } else if ([@"remoteConfigTestingEnrollIntoVariant" isEqualToString:call.method]) {
        NSNumber *callbackID = [command objectAtIndex:0];
        NSString *key = [command objectAtIndex:1];
        NSString *variantName = [command objectAtIndex:2];
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.remoteConfig testingEnrollIntoVariant:key
                                                            variantName:variantName
                                                      completionHandler:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error) {
                                                        [self remoteConfigVariantCallback:callbackID response:response error:error];
                                                      }];
          result(@"Success!");
        });

    } else if ([@"testingDownloadExperimentInformation" isEqualToString:call.method]) {
        NSNumber *callbackID = [command objectAtIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.remoteConfig testingDownloadExperimentInformation:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error) {
            [self remoteConfigVariantCallback:callbackID response:response error:error];
          }];
          result(@"Success!");
        });

    } else if ([@"testingGetAllExperimentInfo" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary<NSString *, CountlyExperimentInformation *> *experiments = [Countly.sharedInstance.remoteConfig testingGetAllExperimentInfo];
          NSMutableArray *experimentInfoArray = [NSMutableArray arrayWithCapacity:experiments.count];
          [experiments enumerateKeysAndObjectsUsingBlock:^(NSString *key, CountlyExperimentInformation *experimentID, BOOL *stop) {
            NSMutableDictionary *experimentInfoValue = [NSMutableDictionary dictionaryWithCapacity:5];
            experimentInfoValue[@"experimentID"] = experimentID.experimentID;
            experimentInfoValue[@"experimentName"] = experimentID.experimentName;
            experimentInfoValue[@"experimentDescription"] = experimentID.experimentDescription;
            if (experimentID.currentVariant) {
                experimentInfoValue[@"currentVariant"] = experimentID.currentVariant;
            } else {
                experimentInfoValue[@"currentVariant"] = @"null";
            }
            experimentInfoValue[@"variants"] = experimentID.variants;
            [experimentInfoArray addObject:experimentInfoValue];
          }];
          result(experimentInfoArray);
        });
    } else if ([@"presentRatingWidgetWithID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *widgetId = [command objectAtIndex:0];
          NSString *unavailableReason = [self ratingWidgetUnavailableReason];
          if (unavailableReason) {
              result([@"presentRatingWidgetWithID failed: " stringByAppendingString:unavailableReason]);
              [callbackChannel invokeMethod:@"ratingWidgetCallback" arguments:unavailableReason];
              return;
          }
          [Countly.sharedInstance presentRatingWidgetWithID:widgetId
                                          completionHandler:^(NSError *error) {
                                            NSString *errorStr = nil;
                                            if (error) {
                                                errorStr = error.localizedDescription;
                                                NSString *theError = [@"presentRatingWidgetWithID failed: " stringByAppendingString:errorStr];
                                                result(theError);
                                            } else {
                                                result(@"presentRatingWidgetWithID success.");
                                            }
                                            [callbackChannel invokeMethod:@"ratingWidgetCallback" arguments:errorStr];
                                          }];
        });
    } else if ([@"setStarRatingDialogTexts" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *starRatingTextMessage = [command objectAtIndex:1];
          config.starRatingMessage = starRatingTextMessage;
          result(@"setStarRatingDialogTexts: success");
        });
    } else if ([@"askForStarRating" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (!CountlyConsentManager.sharedInstance.consentForFeedback) {
              result(@"askForStarRating failed: feedback consent is not given");
              return;
          }
          [Countly.sharedInstance askForStarRating:^(NSInteger rating) {
            result([NSString stringWithFormat:@"Rating:%d", (int)rating]);
          }];
        });
    } else if ([@"getAvailableFeedbackWidgets" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.feedback getAvailableFeedbackWidgets:^(NSArray<CountlyFeedbackWidget *> *feedbackWidgets, NSError *error) {
            if (error) {
                result([FlutterError errorWithCode:@"getAvailableFeedbackWidgets" message:error.localizedDescription details:nil]);
                return;
            }
            feedbackWidgetList = [NSArray arrayWithArray:feedbackWidgets];
            NSMutableArray *feedbackWidgetsArray = [NSMutableArray arrayWithCapacity:feedbackWidgets.count];
            for (CountlyFeedbackWidget *retrievedWidget in feedbackWidgets) {
                NSMutableDictionary *feedbackWidget = [NSMutableDictionary dictionaryWithCapacity:3];
                feedbackWidget[@"id"] = retrievedWidget.ID;
                feedbackWidget[@"type"] = retrievedWidget.type;
                feedbackWidget[@"name"] = retrievedWidget.name;
                [feedbackWidgetsArray addObject:feedbackWidget];
            }
            result(feedbackWidgetsArray);
          }];
        });
    } else if ([@"presentFeedbackWidget" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *widgetId = [command objectAtIndex:0];
          CountlyFeedbackWidget *feedbackWidget = [self getFeedbackWidget:widgetId];
          if (feedbackWidget == nil) {
              NSString *errorMessage = [NSString stringWithFormat:@"[presentFeedbackWidget], No feedbackWidget is found against widget Id : '%@', always call 'getFeedbackWidgets' to get updated list of feedback widgets.", widgetId];
              COUNTLY_FLUTTER_LOG(errorMessage);
              result(errorMessage);
          } else if (!CountlyConsentManager.sharedInstance.consentForFeedback) {
              result(@"presentFeedbackWidget failed: feedback consent is not given");
          } else {
              // The call is answered when the widget appears, or when it closes if it never appeared.
              __block BOOL answered = NO;
              [feedbackWidget
                  presentWithAppearBlock:^{
                    [callbackChannel invokeMethod:@"widgetShown" arguments:nil];
                    if (!answered) {
                        answered = YES;
                        result(@"appeared");
                    }
                  }
                  andDismissBlock:^{
                    [callbackChannel invokeMethod:@"widgetClosed" arguments:nil];
                    if (!answered) {
                        answered = YES;
                        result(@"dismissed");
                    }
                  }];
          }
        });
    } else if ([@"presentNPS" isEqualToString:call.method] || [@"presentRating" isEqualToString:call.method] || [@"presentSurvey" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *nameIDorTag = @"";

          if (command.count != 0) {
              nameIDorTag = [command objectAtIndex:0];
          }

          WidgetCallback widgetCallback = ^(WidgetState state) {
            if (state == WIDGET_CLOSED) {
                [callbackChannel invokeMethod:@"feedbackCallback_onClosed" arguments:nil];
            } else if (state == WIDGET_APPEARED) {
                [callbackChannel invokeMethod:@"feedbackCallback_onFinished" arguments:nil];
            }
          };

          if ([@"presentNPS" isEqualToString:call.method]) {
              [Countly.sharedInstance.feedback presentNPS:nameIDorTag widgetCallback:widgetCallback];
          } else if ([@"presentRating" isEqualToString:call.method]) {
              [Countly.sharedInstance.feedback presentRating:nameIDorTag widgetCallback:widgetCallback];
          } else {
              [Countly.sharedInstance.feedback presentSurvey:nameIDorTag widgetCallback:widgetCallback];
          }

          result([NSString stringWithFormat:@"[CountlyFlutterPlugin] %@, success", call.method]);
        });
    } else if ([@"getFeedbackWidgetData" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *widgetId = [command objectAtIndex:0];
          CountlyFeedbackWidget *feedbackWidget = [self getFeedbackWidget:widgetId];
          NSString *errorMessage = nil;
          if (feedbackWidget == nil) {
              errorMessage = [NSString stringWithFormat:@"[getFeedbackWidgetData], No feedbackWidget is found against widget Id : '%@', always call 'getFeedbackWidgets' to get updated list of feedback widgets.", widgetId];
          } else if (!CountlyServerConfig.sharedInstance.networkingEnabled) {
              errorMessage = @"[getFeedbackWidgetData], SDK networking is disabled by SDK behavior settings";
          }
          if (errorMessage) {
              COUNTLY_FLUTTER_LOG(errorMessage);
              result([FlutterError errorWithCode:@"getFeedbackWidgetData" message:errorMessage details:nil]);
              [self feedbackWidgetDataCallback:NULL error:errorMessage];
              return;
          }
          [feedbackWidget getWidgetData:^(NSDictionary *_Nullable widgetData, NSError *_Nullable error) {
            if (error) {
                NSString *theError = [@"getFeedbackWidgetData failed: " stringByAppendingString:error.localizedDescription];
                result([FlutterError errorWithCode:@"getFeedbackWidgetData" message:theError details:nil]);
                [self feedbackWidgetDataCallback:NULL error:theError];
            } else {
                result(widgetData);
                [self feedbackWidgetDataCallback:widgetData error:NULL];
            }
          }];
        });
    } else if ([@"reportFeedbackWidgetManually" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSArray *widgetInfo = [command objectAtIndex:0];
          //        NSDictionary* widgetData = [command objectAtIndex:1];
          NSDictionary *widgetResult = [command objectAtIndex:2];

          NSString *widgetId = [widgetInfo objectAtIndex:0];

          CountlyFeedbackWidget *feedbackWidget = [self getFeedbackWidget:widgetId];
          if (feedbackWidget == nil) {
              NSString *errorMessage = [NSString stringWithFormat:@"[reportFeedbackWidgetManually], No feedbackWidget is found against widget Id : '%@', always call 'getFeedbackWidgets' to get updated list of feedback widgets.", widgetId];
              COUNTLY_FLUTTER_LOG(errorMessage);
              result(errorMessage);
          } else {
              [feedbackWidget recordResult:widgetResult];
              result(nil);
          }
        });
    } else if ([@"replaceAllAppKeysInQueueWithCurrentAppKey" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance replaceAllAppKeysInQueueWithCurrentAppKey];
        });
        result(@"replaceAllAppKeysInQueueWithCurrentAppKey: success");
    } else if ([@"removeDifferentAppKeysFromQueue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance removeDifferentAppKeysFromQueue];
        });
        result(@"removeDifferentAppKeysFromQueue: success");
    } else if ([@"startTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *traceKey = [command objectAtIndex:0];
          [Countly.sharedInstance startCustomTrace:traceKey];
        });
        result(@"startTrace: success");
    } else if ([@"cancelTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *traceKey = [command objectAtIndex:0];
          [Countly.sharedInstance cancelCustomTrace:traceKey];
        });
        result(@"cancelTrace: success");
    } else if ([@"clearAllTraces" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance clearAllCustomTraces];
        });
        result(@"clearAllTrace: success");
    } else if ([@"endTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *traceKey = [command objectAtIndex:0];
          NSMutableDictionary *metrics = [[NSMutableDictionary alloc] init];
          for (int i = 1, il = (int)command.count; i < il; i += 2) {
              @try {
                  NSString *key = [command objectAtIndex:i];
                  NSString *valueString = [command objectAtIndex:i + 1];
                  // Convert value string to integer
                  NSNumber *value = @([valueString intValue]);
                  metrics[key] = value;
              } @catch (NSException *exception) {
                  COUNTLY_FLUTTER_LOG(@"[endTrace], Exception occurred while parsing metric: %@", exception);
              }
          }
          [Countly.sharedInstance endCustomTrace:traceKey metrics:metrics];
        });
        result(@"endTrace: success");
    } else if ([@"recordNetworkTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          @try {
              NSString *networkTraceKey = [command objectAtIndex:0];
              int responseCode = [[command objectAtIndex:1] intValue];
              int requestPayloadSize = [[command objectAtIndex:2] intValue];
              int responsePayloadSize = [[command objectAtIndex:3] intValue];
              long long startTime = [[command objectAtIndex:4] longLongValue];
              long long endTime = [[command objectAtIndex:5] longLongValue];
              [Countly.sharedInstance recordNetworkTrace:networkTraceKey requestPayloadSize:requestPayloadSize responsePayloadSize:responsePayloadSize responseStatusCode:responseCode startTime:startTime endTime:endTime];
          } @catch (NSException *exception) {
              COUNTLY_FLUTTER_LOG(@"Exception occured at recordNetworkTrace method: %@", exception);
          }
        });
        result(@"recordNetworkTrace: success");
    } else if ([@"throwNativeException" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSException *e = [NSException exceptionWithName:@"Native Exception Crash!" reason:@"Throw Native Exception..." userInfo:nil];
          @throw e;
        });
    } else if ([@"recordDirectAttribution" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *campaignType = [command objectAtIndex:0];
          NSString *campaignData = [command objectAtIndex:1];
          if (CountlyCommon.sharedInstance.hasStarted) {
              [Countly.sharedInstance recordDirectAttributionWithCampaignType:campaignType andCampaignData:campaignData];
          } else {
              config.campaignType = campaignType;
              config.campaignData = campaignData;
          }
          result(nil);
        });
    } else if ([@"recordIndirectAttribution" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *attributionValues = [command objectAtIndex:0];
          if (CountlyCommon.sharedInstance.hasStarted) {
              [Countly.sharedInstance recordIndirectAttribution:attributionValues];
          } else {
              config.indirectAttribution = attributionValues;
          }
          result(nil);
        });
    } else if ([@"startView" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewName = [command objectAtIndex:0];
          NSDictionary *segmentation = [command objectAtIndex:1];
          NSString *viewId = [Countly.sharedInstance.views startView:viewName segmentation:segmentation];
          result(viewId);
        });
    } else if ([@"startAutoStoppedView" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewName = [command objectAtIndex:0];
          NSDictionary *segmentation = [command objectAtIndex:1];
          NSString *viewId = [Countly.sharedInstance.views startAutoStoppedView:viewName segmentation:segmentation];
          result(viewId);
        });
    } else if ([@"stopAllViews" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *segmentation = [command objectAtIndex:0];
          [Countly.sharedInstance.views stopAllViews:segmentation];
          result(nil);
        });
    } else if ([@"stopViewWithID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewId = [command objectAtIndex:0];
          NSDictionary *segmentation = [command objectAtIndex:1];
          [Countly.sharedInstance.views stopViewWithID:viewId segmentation:segmentation];
          result(nil);
        });
    } else if ([@"stopViewWithName" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewName = [command objectAtIndex:0];
          NSDictionary *segmentation = [command objectAtIndex:1];
          [Countly.sharedInstance.views stopViewWithName:viewName segmentation:segmentation];
          result(nil);
        });
    } else if ([@"pauseViewWithID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewId = [command objectAtIndex:0];
          [Countly.sharedInstance.views pauseViewWithID:viewId];
          result(nil);
        });
    } else if ([@"resumeViewWithID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewId = [command objectAtIndex:0];
          [Countly.sharedInstance.views resumeViewWithID:viewId];
          result(nil);
        });
    } else if ([@"setGlobalViewSegmentation" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *segmentation = [command objectAtIndex:0];
          [Countly.sharedInstance.views setGlobalViewSegmentation:segmentation];
          result(nil);
        });
    } else if ([@"updateGlobalViewSegmentation" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *segmentation = [command objectAtIndex:0];
          [Countly.sharedInstance.views updateGlobalViewSegmentation:segmentation];
          result(nil);
        });
    } else if ([@"addSegmentationToViewWithID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewId = [command objectAtIndex:0];
          NSDictionary *segmentation = [command objectAtIndex:1];
          [Countly.sharedInstance.views addSegmentationToViewWithID:viewId segmentation:segmentation];
          result(nil);
        });
    } else if ([@"addSegmentationToViewWithName" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSString *viewName = [command objectAtIndex:0];
          NSDictionary *segmentation = [command objectAtIndex:1];
          [Countly.sharedInstance.views addSegmentationToViewWithName:viewName segmentation:segmentation];
          result(nil);
        });
    } else if ([@"appLoadingFinished" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance appLoadingFinished];
        });
        result(@"appLoadingFinished: success");
    } else if ([@"enterContentZone" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.content enterContentZone];
          result(nil);
        });
    } else if ([@"exitContentZone" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.content exitContentZone];
          result(nil);
        });
    } else if ([@"refreshContentZone" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.content refreshContentZone];
          result(nil);
        });
    } else if ([@"previewContent" isEqualToString:call.method]) {
        NSString *contentId = call.arguments[@"contentId"];
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance.content previewContent:contentId];
          result(nil);
        });
    } else if ([@"attemptToSendStoredRequests" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [Countly.sharedInstance attemptToSendStoredRequests];
        });
        result(@"attemptToSendStoredRequests: success");
    } else if ([@"addCustomNetworkRequestHeaders" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *customHeaderValues = [command objectAtIndex:0];
          [Countly.sharedInstance addCustomNetworkRequestHeaders:customHeaderValues];
          result(nil);
        });
    } else if ([@"recordMetrics" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSDictionary *metricsOverride = [command objectAtIndex:0];
          [Countly.sharedInstance recordMetrics:metricsOverride];
          result(nil);
        });
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)setUserData:(NSDictionary *__nullable)userData {
    NSString *name = userData[NAME_KEY];
    NSString *username = userData[USERNAME_KEY];
    NSString *email = userData[EMAIL_KEY];
    NSString *organization = userData[ORG_KEY];
    NSString *phone = userData[PHONE_KEY];
    NSString *picture = userData[PICTURE_KEY];
    NSString *picturePath = userData[PICTURE_PATH_KEY];
    NSString *gender = userData[GENDER_KEY];
    NSString *byear = userData[BYEAR_KEY];

    if (name) {
        Countly.user.name = name;
    }
    if (username) {
        Countly.user.username = username;
    }
    if (email) {
        Countly.user.email = email;
    }
    if (organization) {
        Countly.user.organization = organization;
    }
    if (phone) {
        Countly.user.phone = phone;
    }
    if (picture) {
        Countly.user.pictureURL = picture;
    }
    if (picturePath) {
        Countly.user.pictureLocalPath = picturePath;
    }
    if (gender) {
        Countly.user.gender = gender;
    }
    if (byear) {
        Countly.user.birthYear = @([byear integerValue]);
    }
}
- (void)feedbackWidgetDataCallback:(NSDictionary *__nullable)widgetData error:(NSString *__nullable)error {
    NSMutableDictionary *feedbackWidgetData = [[NSMutableDictionary alloc] init];
    if (widgetData) {
        feedbackWidgetData[@"widgetData"] = widgetData;
    }
    if (error) {
        feedbackWidgetData[@"error"] = error;
    }
    [callbackChannel invokeMethod:@"feedbackWidgetDataCallback" arguments:feedbackWidgetData];
}

- (void)remoteConfigVariantCallback:(NSNumber *)callbackID response:(CLYRequestResult _Nonnull)response error:(NSError *__nullable)error {
    NSMutableDictionary *remoteConfigData = [[NSMutableDictionary alloc] init];

    remoteConfigData[@"id"] = callbackID;
    if (response == CLYResponseSuccess) {
        remoteConfigData[@"requestResult"] = [NSNumber numberWithInt:0];
    } else if (response == CLYResponseNetworkIssue) {
        remoteConfigData[@"requestResult"] = [NSNumber numberWithInt:1];
    } else {
        remoteConfigData[@"requestResult"] = [NSNumber numberWithInt:2];
    }

    if (error) {
        remoteConfigData[@"error"] = error.description;
    }

    [callbackChannel invokeMethod:@"remoteConfigVariantCallback" arguments:remoteConfigData];
}

- (void)remoteConfigDownloadCallback:(NSNumber *)callbackID response:(CLYRequestResult _Nonnull)response fullValueUpdate:(BOOL)fullValueUpdate error:(NSError *__nullable)error downloadedValues:(NSDictionary<NSString *, CountlyRCData *> *_Nonnull)downloadedValues {
    COUNTLY_FLUTTER_LOG(@"[remoteConfigDownloadCallback], about to notify flutter side callback", callbackID);
    if ([callbackID intValue] == -1) {
        return;
    }
    NSMutableDictionary *remoteConfigData = [[NSMutableDictionary alloc] init];

    remoteConfigData[@"id"] = callbackID;
    if (response == CLYResponseSuccess) {
        remoteConfigData[@"requestResult"] = [NSNumber numberWithInt:0];
    } else if (response == CLYResponseNetworkIssue) {
        remoteConfigData[@"requestResult"] = [NSNumber numberWithInt:1];
    } else {
        remoteConfigData[@"requestResult"] = [NSNumber numberWithInt:2];
    }

    remoteConfigData[@"fullValueUpdate"] = fullValueUpdate ? @YES : @NO;

    if (downloadedValues) {
        remoteConfigData[@"downloadedValues"] = [self getRCValues:downloadedValues];
    }
    if (error) {
        remoteConfigData[@"error"] = error.description;
    }

    [callbackChannel invokeMethod:@"remoteConfigDownloadCallback" arguments:remoteConfigData];
}

- (NSDictionary *)getRCValues:(NSDictionary<NSString *, CountlyRCData *> *_Nonnull)downloadedValues {
    NSMutableDictionary *remoteConfigValues = [[NSMutableDictionary alloc] init];
    [downloadedValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, CountlyRCData *rcData, BOOL *stop) {
      remoteConfigValues[key] = [self rcDataToMap:rcData];
    }];
    return remoteConfigValues;
}

- (NSDictionary *)rcDataToMap:(CountlyRCData *)rcData {
    NSMutableDictionary *rCDataMap = [[NSMutableDictionary alloc] init];
    rCDataMap[@"value"] = rcData.value;
    rCDataMap[@"isCurrentUsersData"] = rcData.isCurrentUsersData ? @YES : @NO;
    return rCDataMap;
}

- (CountlyFeedbackWidget *)getFeedbackWidget:(NSString *)widgetId {
    if (feedbackWidgetList == nil) {
        return nil;
    }
    for (CountlyFeedbackWidget *feedbackWidget in feedbackWidgetList) {
        if ([feedbackWidget.ID isEqual:widgetId]) {
            return feedbackWidget;
        }
    }
    return nil;
}
- (CLLocationCoordinate2D)getCoordinate:(NSString *)gpsCoordinate {
    CLLocationCoordinate2D locationCoordinate = kCLLocationCoordinate2DInvalid;
    if (gpsCoordinate && ![[NSNull null] isEqual:gpsCoordinate] && gpsCoordinate.length) {
        if ([gpsCoordinate containsString:@","]) {
            @try {
                NSArray *locationArray = [gpsCoordinate componentsSeparatedByString:@","];
                if (locationArray.count > 2) {
                    COUNTLY_FLUTTER_LOG(@"[getCoordinate], Invalid location Coordinates:[%@], it should contains only two comma seperated values", gpsCoordinate);
                }
                NSString *latitudeString = [locationArray objectAtIndex:0];
                NSString *longitudeString = [locationArray objectAtIndex:1];

                double latitudeDouble = [latitudeString doubleValue];
                double longitudeDouble = [longitudeString doubleValue];
                if (latitudeDouble == 0 || longitudeDouble == 0) {
                    COUNTLY_FLUTTER_LOG(@"[getCoordinate], Invalid location Coordinates, One of the values parsed to a 0, double check that given coordinates are correct:[%@]", gpsCoordinate);
                }
                locationCoordinate = (CLLocationCoordinate2D){latitudeDouble, longitudeDouble};
            } @catch (NSException *exception) {
                COUNTLY_FLUTTER_LOG(@"[getCoordinate], Invalid location Coordinates:[%@], Exception occurred while parsing Coordinates:[%@]", gpsCoordinate, exception);
            }
        } else {
            COUNTLY_FLUTTER_LOG(@"[getCoordinate], Invalid location Coordinates:[%@], lat and long values should be comma separated", gpsCoordinate);
        }
    }
    return locationCoordinate;
}

- (void)populateConfig:(NSDictionary *)_config {
    @try {
        NSString *appKey = [self configValueFrom:_config key:@"appKey" ofClass:NSString.class];
        if (appKey) {
            config.appKey = appKey;
        }
        NSString *host = [self configValueFrom:_config key:@"serverURL" ofClass:NSString.class];
        if (host) {
            config.host = host;
        }
        NSString *deviceID = [self configValueFrom:_config key:@"deviceID" ofClass:NSString.class];
        if (deviceID) {
            if ([@"CLYTemporaryDeviceID" isEqualToString:deviceID]) {
                [config enableTemporaryDeviceIDMode];
            } else {
                config.deviceID = deviceID;
            }
        }
        NSNumber *loggingEnabled = [self configValueFrom:_config key:@"loggingEnabled" ofClass:NSNumber.class];
        if (loggingEnabled) {
            config.enableDebug = [loggingEnabled boolValue];
        }
        NSNumber *locationDisabled = [self configValueFrom:_config key:@"locationDisabled" ofClass:NSNumber.class];
        if (locationDisabled) {
            config.disableLocation = [locationDisabled boolValue];
        }
        NSNumber *httpPostForced = [self configValueFrom:_config key:@"httpPostForced" ofClass:NSNumber.class];
        if (httpPostForced) {
            config.alwaysUsePOST = [httpPostForced boolValue];
        }
        NSDictionary *customNetworkRequestHeaders = [self configValueFrom:_config key:@"customNetworkRequestHeaders" ofClass:NSDictionary.class];
        if (customNetworkRequestHeaders) {
            NSURLSessionConfiguration *session = [NSURLSessionConfiguration defaultSessionConfiguration];
            session.HTTPAdditionalHeaders = customNetworkRequestHeaders;
            config.URLSessionConfiguration = session;
        }
        NSNumber *shouldRequireConsent = [self configValueFrom:_config key:@"shouldRequireConsent" ofClass:NSNumber.class];
        if (shouldRequireConsent) {
            config.requiresConsent = [shouldRequireConsent boolValue];
        }
        NSArray *consents = [self configValueFrom:_config key:@"consents" ofClass:NSArray.class];
        NSNumber *enableAllConsents = [self configValueFrom:_config key:@"enableAllConsents" ofClass:NSNumber.class];
        if (enableAllConsents) {
            config.enableAllConsents = [enableAllConsents boolValue];
        } else if (consents) {
            config.consents = [self iOSConsentsFrom:consents];
        }

        NSNumber *eventQueueSizeThreshold = [self configValueFrom:_config key:@"eventQueueSizeThreshold" ofClass:NSNumber.class];
        if (eventQueueSizeThreshold) {
            config.eventSendThreshold = [eventQueueSizeThreshold intValue];
        }
        NSNumber *sessionUpdateTimerDelay = [self configValueFrom:_config key:@"sessionUpdateTimerDelay" ofClass:NSNumber.class];
        if (sessionUpdateTimerDelay) {
            if ([sessionUpdateTimerDelay intValue] >= 1) {
                config.updateSessionPeriod = [sessionUpdateTimerDelay intValue];
            } else {
                COUNTLY_FLUTTER_LOG(@"[populateConfig], sessionUpdateTimerDelay must be at least 1 second, ignoring [%@]", sessionUpdateTimerDelay);
            }
        }
        NSString *salt = [self configValueFrom:_config key:@"tamperingProtectionSalt" ofClass:NSString.class];
        if (salt) {
            config.secretSalt = salt;
        }

        NSDictionary *crashSegmentation = [self configValueFrom:_config key:@"customCrashSegment" ofClass:NSDictionary.class];
        if (crashSegmentation) {
            config.crashSegmentation = crashSegmentation;
        }

        NSDictionary *providedUserProperties = [self configValueFrom:_config key:@"providedUserProperties" ofClass:NSDictionary.class];
        if (providedUserProperties) {
            config.providedUserProperties = providedUserProperties;
        }

        NSString *starRatingTextMessage = [self configValueFrom:_config key:@"starRatingTextMessage" ofClass:NSString.class];
        if (starRatingTextMessage) {
            config.starRatingMessage = starRatingTextMessage;
        }
        NSNumber *enableForegroundBackground = [self configValueFrom:_config key:@"enableForegroundBackground" ofClass:NSNumber.class];
        if (enableForegroundBackground) {
            config.apm.enableForegroundBackgroundTracking = [enableForegroundBackground boolValue];
        }
        NSNumber *enableManualAppLoaded = [self configValueFrom:_config key:@"enableManualAppLoaded" ofClass:NSNumber.class];
        if (enableManualAppLoaded) {
            config.apm.enableManualAppLoadedTrigger = [enableManualAppLoaded boolValue];
        }
        NSNumber *trackAppStartTime = [self configValueFrom:_config key:@"trackAppStartTime" ofClass:NSNumber.class];
        if (trackAppStartTime) {
            config.apm.enableAppStartTimeTracking = [trackAppStartTime boolValue];
        }
        NSNumber *startTSOverride = [self configValueFrom:_config key:@"startTSOverride" ofClass:NSNumber.class];
        if (startTSOverride) {
            [config.apm setAppStartTimestampOverride:[startTSOverride longLongValue]];
        }

        NSString *sdkBehaviorSettings = [self configValueFrom:_config key:@"sdkBehaviorSettings" ofClass:NSString.class];
        if (sdkBehaviorSettings) {
            config.sdkBehaviorSettings = sdkBehaviorSettings;
        }

        NSNumber *backoffMechanismDisabled = [self configValueFrom:_config key:@"backoffMechanismDisabled" ofClass:NSNumber.class];
        if (backoffMechanismDisabled && [backoffMechanismDisabled boolValue]) {
            config.disableBackoffMechanism = YES;
        }

        if (_config[@"sdkBehaviorSettingsUpdatesDisabled"]) {
            config.disableSDKBehaviorSettingsUpdates = YES;
        }

        // Internal Limits ---------------------
        NSNumber *maxKeyLength = [self configValueFrom:_config key:@"maxKeyLength" ofClass:NSNumber.class];
        if (maxKeyLength) {
            [config.sdkInternalLimits setMaxKeyLength:[maxKeyLength intValue]];
        }
        NSNumber *maxValueSize = [self configValueFrom:_config key:@"maxValueSize" ofClass:NSNumber.class];
        if (maxValueSize) {
            [config.sdkInternalLimits setMaxValueSize:[maxValueSize intValue]];
        }
        NSNumber *maxSegmentationValues = [self configValueFrom:_config key:@"maxSegmentationValues" ofClass:NSNumber.class];
        if (maxSegmentationValues) {
            [config.sdkInternalLimits setMaxSegmentationValues:[maxSegmentationValues intValue]];
        }
        NSNumber *maxBreadcrumbCount = [self configValueFrom:_config key:@"maxBreadcrumbCount" ofClass:NSNumber.class];
        if (maxBreadcrumbCount) {
            [config.sdkInternalLimits setMaxBreadcrumbCount:[maxBreadcrumbCount intValue]];
        }
        NSNumber *maxStackTraceLineLength = [self configValueFrom:_config key:@"maxStackTraceLineLength" ofClass:NSNumber.class];
        if (maxStackTraceLineLength) {
            [config.sdkInternalLimits setMaxStackTraceLineLength:[maxStackTraceLineLength intValue]];
        }
        NSNumber *maxStackTraceLinesPerThread = [self configValueFrom:_config key:@"maxStackTraceLinesPerThread" ofClass:NSNumber.class];
        if (maxStackTraceLinesPerThread) {
            [config.sdkInternalLimits setMaxStackTraceLinesPerThread:[maxStackTraceLinesPerThread intValue]];
        }
        NSNumber *maxValueSizePicture = [self configValueFrom:_config key:@"maxValueSizePicture" ofClass:NSNumber.class];
        if (maxValueSizePicture) {
            [config.sdkInternalLimits setMaxValueSizePicture:[maxValueSizePicture intValue]];
        }
        // Internal Limits End ---------------------

        NSNumber *enableUnhandledCrashReporting = [self configValueFrom:_config key:@"enableUnhandledCrashReporting" ofClass:NSNumber.class];
        if (enableUnhandledCrashReporting && [enableUnhandledCrashReporting boolValue]) {
            [self addCountlyFeature:CLYCrashReporting];
        }

        NSNumber *maxRequestQueueSize = [self configValueFrom:_config key:@"maxRequestQueueSize" ofClass:NSNumber.class];
        if (maxRequestQueueSize) {
            config.storedRequestsLimit = [maxRequestQueueSize intValue];
        }

        NSNumber *requestDropAgeHours = [self configValueFrom:_config key:@"requestDropAgeHours" ofClass:NSNumber.class];
        if (requestDropAgeHours) {
            config.requestDropAgeHours = [requestDropAgeHours intValue];
        }

        NSNumber *requestTimeoutDuration = [self configValueFrom:_config key:@"requestTimeoutDuration" ofClass:NSNumber.class];
        if (requestTimeoutDuration) {
            config.requestTimeoutDuration = [requestTimeoutDuration intValue];
        }

        NSNumber *manualSessionEnabled = [self configValueFrom:_config key:@"manualSessionEnabled" ofClass:NSNumber.class];
        if (manualSessionEnabled && [manualSessionEnabled boolValue]) {
            config.manualSessionHandling = YES;
        }
        NSNumber *manualSessionControlHybridMode = [self configValueFrom:_config key:@"manualSessionControlHybridMode" ofClass:NSNumber.class];
        if (manualSessionControlHybridMode && [manualSessionControlHybridMode boolValue]) {
            config.enableManualSessionControlHybridMode = YES;
        }
        [config remoteConfigRegisterGlobalCallback:^(CLYRequestResult _Nonnull response, NSError *_Nonnull error, BOOL fullValueUpdate, NSDictionary<NSString *, CountlyRCData *> *_Nonnull downloadedValues) {
          [self remoteConfigDownloadCallback:[NSNumber numberWithInt:-2] response:response fullValueUpdate:fullValueUpdate error:error downloadedValues:downloadedValues];
        }];

        NSNumber *remoteConfigAutomaticTriggers = [self configValueFrom:_config key:@"remoteConfigAutomaticTriggers" ofClass:NSNumber.class];
        if (remoteConfigAutomaticTriggers) {
            config.enableRemoteConfigAutomaticTriggers = [remoteConfigAutomaticTriggers boolValue];
        }

        NSNumber *remoteConfigValueCaching = [self configValueFrom:_config key:@"remoteConfigValueCaching" ofClass:NSNumber.class];
        if (remoteConfigValueCaching) {
            config.enableRemoteConfigValueCaching = [remoteConfigValueCaching boolValue];
        }

        NSNumber *autoEnrollABOnDownload = [self configValueFrom:_config key:@"autoEnrollABOnDownload" ofClass:NSNumber.class];
        if (autoEnrollABOnDownload && [autoEnrollABOnDownload boolValue]) {
            config.enrollABOnRCDownload = YES;
        }

        NSDictionary *globalViewSegmentation = [self configValueFrom:_config key:@"globalViewSegmentation" ofClass:NSDictionary.class];
        if (globalViewSegmentation) {
            config.globalViewSegmentation = globalViewSegmentation;
        }

        NSNumber *disableViewRestartForManualRecording = [self configValueFrom:_config key:@"disableViewRestartForManualRecording" ofClass:NSNumber.class];
        if (disableViewRestartForManualRecording && [disableViewRestartForManualRecording boolValue]) {
            config.disableViewRestartForManualRecording = YES;
        }

        NSDictionary *metricOverride = [self configValueFrom:_config key:@"metricOverride" ofClass:NSDictionary.class];
        if (metricOverride) {
            config.customMetrics = metricOverride;
        }
        NSNumber *trackOrientationChanges = [self configValueFrom:_config key:@"trackOrientationChanges" ofClass:NSNumber.class];
        if (trackOrientationChanges) {
            config.enableOrientationTracking = [trackOrientationChanges boolValue];
        }
        NSNumber *clearStoredDeviceId = [self configValueFrom:_config key:@"clearStoredDeviceId" ofClass:NSNumber.class];
        if (clearStoredDeviceId && [clearStoredDeviceId boolValue]) {
            config.resetStoredDeviceID = YES;
        }

        NSString *gpsCoordinate = [self configValueFrom:_config key:@"locationGpsCoordinates" ofClass:NSString.class];
        CLLocationCoordinate2D coordinate = [self getCoordinate:gpsCoordinate];
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            config.location = coordinate;
        }
        NSString *city = [self configValueFrom:_config key:@"locationCity" ofClass:NSString.class];
        if (city) {
            config.city = city;
        }
        NSString *countryCode = [self configValueFrom:_config key:@"locationCountryCode" ofClass:NSString.class];
        if (countryCode) {
            config.ISOCountryCode = countryCode;
        }

        NSString *ipAddress = [self configValueFrom:_config key:@"locationIpAddress" ofClass:NSString.class];
        if (ipAddress) {
            config.IP = ipAddress;
        }

        NSString *campaignType = [self configValueFrom:_config key:@"campaignType" ofClass:NSString.class];
        if (campaignType) {
            config.campaignType = campaignType;
            config.campaignData = [self configValueFrom:_config key:@"campaignData" ofClass:NSString.class];
        }

        NSDictionary *attributionValues = [self configValueFrom:_config key:@"attributionValues" ofClass:NSDictionary.class];
        if (attributionValues) {
            config.indirectAttribution = attributionValues;
        }

        NSNumber *visibilityTracking = [self configValueFrom:_config key:@"visibilityTracking" ofClass:NSNumber.class];
        if (visibilityTracking) {
            config.experimental.enableVisibiltyTracking = [visibilityTracking boolValue];
        }
        NSNumber *previousNameRecording = [self configValueFrom:_config key:@"previousNameRecording" ofClass:NSNumber.class];
        if (previousNameRecording) {
            config.experimental.enablePreviousNameRecording = [previousNameRecording boolValue];
        }

#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        NSNumber *sendPushTokenAlways = [self configValueFrom:_config key:@"sendPushTokenAlways" ofClass:NSNumber.class];
        if (sendPushTokenAlways && [sendPushTokenAlways boolValue]) {
            config.sendPushTokenAlways = YES;
        }
        NSNumber *doNotShowAlertForNotifications = [self configValueFrom:_config key:@"doNotShowAlertForNotifications" ofClass:NSNumber.class];
        if (doNotShowAlertForNotifications && [doNotShowAlertForNotifications boolValue]) {
            config.doNotShowAlertForNotifications = YES;
        }
#endif

        [config.content setGlobalContentCallback:^(ContentStatus contentStatus, NSDictionary *contentData) {
          NSMutableDictionary *contentCallbackData = [NSMutableDictionary dictionary];
          int contentResult = 0; // COMPLETED = 0, CLOSED = 1

          if (contentStatus == CLOSED) {
              contentResult = 1;
          }

          contentCallbackData[@"contentResult"] = @(contentResult);
          contentCallbackData[@"contentData"] = contentData;

          [callbackChannel invokeMethod:@"contentCallback" arguments:contentCallbackData];
        }];

        NSNumber *zoneTimerInterval = [self configValueFrom:_config key:@"zoneTimerInterval" ofClass:NSNumber.class];
        if (zoneTimerInterval) {
            [config.content setZoneTimerInterval:[zoneTimerInterval unsignedIntValue]];
        }

        NSString *webviewDisplayOption = [self configValueFrom:_config key:@"webviewDisplayOption" ofClass:NSString.class];
        if (webviewDisplayOption) {
            if ([webviewDisplayOption isEqualToString:@"IMMERSIVE"]) {
                [config.content setWebviewDisplayOption:IMMERSIVE];
            } else if ([webviewDisplayOption isEqualToString:@"SAFE_AREA"]) {
                [config.content setWebviewDisplayOption:SAFE_AREA];
            }
        }

        NSNumber *contentZoomDisabled = [self configValueFrom:_config key:@"contentZoomDisabled" ofClass:NSNumber.class];
        if (contentZoomDisabled && [contentZoomDisabled boolValue]) {
            [config.content disableZoom];
        }
        NSNumber *contentRotationDisabled = [self configValueFrom:_config key:@"contentRotationDisabled" ofClass:NSNumber.class];
        if (contentRotationDisabled && [contentRotationDisabled boolValue]) {
            [config.content disableRotation];
        }
        NSNumber *contentReloadOnStallEnabled = [self configValueFrom:_config key:@"contentReloadOnStallEnabled" ofClass:NSNumber.class];
        if (contentReloadOnStallEnabled && [contentReloadOnStallEnabled boolValue]) {
            [config.content enableContentReloadOnStall];
        }
        NSNumber *contentReloadOnStallTimeout = [self configValueFrom:_config key:@"contentReloadOnStallTimeout" ofClass:NSNumber.class];
        if (contentReloadOnStallTimeout) {
            [config.content setContentReloadOnStallTimeout:[contentReloadOnStallTimeout unsignedIntegerValue]];
        }

    } @catch (NSException *exception) {
        COUNTLY_FLUTTER_LOG(@"[populateConfig], Unable to parse Config object: %@", exception);
    }
}

/**
 * Returns the config value for the key when it has the expected class, which is NSNumber for JSON
 * booleans and numbers. A value of another type is logged and skipped, so it cannot raise an
 * exception that would skip the remaining settings.
 */
- (id)configValueFrom:(NSDictionary *)config key:(NSString *)key ofClass:(Class)expectedClass {
    id value = config[key];
    if (value == nil || [value isKindOfClass:expectedClass]) {
        return value;
    }
    COUNTLY_FLUTTER_LOG(@"[populateConfig], ignoring [%@]: expected %@, got [%@]", key, NSStringFromClass(expectedClass), NSStringFromClass([value class]));
    return nil;
}

/**
 * Translates consent names from Dart to the iOS SDK. iOS has no separate star rating consent:
 * its star rating dialog follows the feedback consent, so "star-rating" gives or removes "feedback".
 */
- (NSArray *)iOSConsentsFrom:(NSArray *)consents {
    if (![consents containsObject:CountlyStarRatingConsent]) {
        return consents;
    }
    NSMutableArray *translated = [NSMutableArray arrayWithCapacity:consents.count];
    for (id consent in consents) {
        id iOSConsent = [CountlyStarRatingConsent isEqual:consent] ? CLYConsentFeedback : consent;
        if (![translated containsObject:iOSConsent]) {
            [translated addObject:iOSConsent];
        }
    }
    return translated;
}

/**
 * Returns why the iOS SDK would skip a remote config download without calling back, or nil when
 * it can run.
 */
- (NSString *)remoteConfigUnavailableReason {
    if (!CountlyConsentManager.sharedInstance.consentForRemoteConfig) {
        return @"Remote config consent is not given";
    }
    if (CountlyDeviceInfo.sharedInstance.isDeviceIDTemporary) {
        return @"Remote config is not available in temporary device ID mode";
    }
    return nil;
}

/**
 * Answers a remote config download with an error when the iOS SDK would skip it without calling back.
 *
 * @return YES when the download was answered here and must not be started
 */
- (BOOL)rejectRemoteConfigDownloadIfUnavailable:(NSNumber *)callbackID {
    NSString *unavailableReason = [self remoteConfigUnavailableReason];
    if (!unavailableReason) {
        return NO;
    }
    NSError *error = [NSError errorWithDomain:@"CountlyFlutterPlugin" code:0 userInfo:@{NSLocalizedDescriptionKey : unavailableReason}];
    [self remoteConfigDownloadCallback:callbackID response:CLYResponseError fullValueUpdate:NO error:error downloadedValues:@{}];
    return YES;
}

/**
 * Returns why the iOS SDK would skip a rating widget without calling back, or nil when it can run.
 */
- (NSString *)ratingWidgetUnavailableReason {
    if (!CountlyServerConfig.sharedInstance.networkingEnabled) {
        return @"SDK networking is disabled by SDK behavior settings";
    }
    if (!CountlyConsentManager.sharedInstance.consentForFeedback) {
        return @"feedback consent is not given";
    }
    if (CountlyDeviceInfo.sharedInstance.isDeviceIDTemporary) {
        return @"feedback is not available in temporary device ID mode";
    }
    return nil;
}

#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
+ (void)startObservingNotifications {
    [CountlyFLPushNotifications.sharedInstance startObservingNotifications];
}

+ (void)onNotification:(NSDictionary *_Nullable)notification {
    [CountlyFLPushNotifications.sharedInstance onNotification:notification];
}
+ (void)onNotificationResponse:(UNNotificationResponse *_Nullable)response {
    [CountlyFLPushNotifications.sharedInstance onNotificationResponse:response];
}
#else
/**
 * Does nothing: push notifications are not part of the no-push flavour, but the method stays so
 * an app delegate written for the push flavour keeps working.
 */
+ (void)startObservingNotifications {
    COUNTLY_FLUTTER_LOG(@"startObservingNotifications, push notifications are not available in this flavour");
}

/**
 * Does nothing: push notifications are not part of the no-push flavour, but the method stays so
 * an app delegate written for the push flavour keeps working.
 */
+ (void)onNotification:(NSDictionary *_Nullable)notification {
    COUNTLY_FLUTTER_LOG(@"onNotification, push notifications are not available in this flavour");
}
#endif

/**
 * Records the actions of push notifications that were tapped before the SDK started.
 */
- (void)recordPushAction {
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
    [CountlyFLPushNotifications.sharedInstance recordPushActions];
#endif
}

- (void)addCountlyFeature:(CLYFeature)feature {
    if (countlyFeatures == nil) {
        countlyFeatures = [[NSMutableArray alloc] init];
    }
    if (![countlyFeatures containsObject:feature]) {
        [countlyFeatures addObject:feature];
        config.features = countlyFeatures;
    }
}

- (void)removeCountlyFeature:(CLYFeature)feature {
    if (countlyFeatures == nil) {
        return;
    }
    if (![countlyFeatures containsObject:feature]) {
        [countlyFeatures removeObject:feature];
        config.features = countlyFeatures;
    }
}

void CountlyFlutterInternalLog(NSString *format, ...) {
    if (!config.enableDebug)
        return;

    va_list args;
    va_start(args, format);

    NSString *logString = [NSString.alloc initWithFormat:format arguments:args];
    NSLog(@"[CountlyFlutterPlugin] %@", logString);

    va_end(args);
}

- (NSString *)toJSON:(NSObject *)json {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];

    if (!jsonData) {
        return @"";
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
}
@end
