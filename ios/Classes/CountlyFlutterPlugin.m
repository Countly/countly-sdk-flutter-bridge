#import "CountlyFlutterPlugin.h"
#import "Countly.h"
#import "CountlyConfig.h"
#import "CountlyCommon.h"
#import "CountlyDeviceInfo.h"
#import "CountlyRemoteConfig.h"

#if DEBUG
#define COUNTLY_FLUTTER_LOG(fmt, ...) CountlyFlutterInternalLog(fmt, ##__VA_ARGS__)
#else
#define COUNTLY_FLUTTER_LOG(...)
#endif

@interface CountlyFeedbackWidget ()
+ (CountlyFeedbackWidget *)createWithDictionary:(NSDictionary *)dictionary;
@end

NSString* const kCountlyFlutterSDKVersion = @"21.11.0";
NSString* const kCountlyFlutterSDKName = @"dart-flutterb-ios";

FlutterResult notificationListener = nil;
NSDictionary *lastStoredNotification = nil;
NSMutableArray *notificationIDs = nil;        // alloc here
NSMutableArray<CLYFeature>* countlyFeatures = nil;
BOOL enablePushNotifications = true;

NSArray<CountlyFeedbackWidget*>* feedbackWidgetList = nil;

@implementation CountlyFlutterPlugin

CountlyConfig* config = nil;
Boolean isInitialized = false;
NSMutableDictionary *networkRequest = nil;
FlutterMethodChannel* _channel;
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  _channel = [FlutterMethodChannel
      methodChannelWithName:@"countly_flutter"
            binaryMessenger:[registrar messenger]];
  CountlyFlutterPlugin* instance = [[CountlyFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:_channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* commandString = call.arguments[@"data"];
    if(commandString == nil){
        commandString = @"[]";
    }
    NSData* data = [commandString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSArray *command = [NSJSONSerialization JSONObjectWithData:data options:nil error:&e];

    if(config == nil){
        config = CountlyConfig.new;
    }

    if([@"init" isEqualToString:call.method]){
        NSDictionary* _config = [command objectAtIndex:0];
        [self populateConfig:_config];
        CountlyCommon.sharedInstance.SDKName = kCountlyFlutterSDKName;
        CountlyCommon.sharedInstance.SDKVersion = kCountlyFlutterSDKVersion;

        //should only be used for silent pushes if explicitly enabled
        //config.sendPushTokenAlways = YES;
#if (TARGET_OS_IOS)
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        if(enablePushNotifications) {
            [self addCountlyFeature:CLYPushNotifications];
        }
#endif
#endif
        if (config.host && [config.host length] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^ {
              isInitialized = true;
              [[Countly sharedInstance] startWithConfig:config];
              [self recordPushAction];
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
    }else if ([@"isInitialized" isEqualToString:call.method]) {
        if(isInitialized){
            result(@"true");
        }else{
            result(@"false");
        }
    }else if ([@"recordEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* key = [command objectAtIndex:0];
        NSString* countString = [command objectAtIndex:1];
        int count = [countString intValue];
        NSString* sumString = [command objectAtIndex:2];
        float sum = [sumString floatValue];
        NSString* durationString = [command objectAtIndex:3];
        int duration = [durationString intValue];
        NSMutableDictionary *segmentation = [[NSMutableDictionary alloc] init];

        if((int)command.count > 4){
            for(int i=4,il=(int)command.count;i<il;i+=2){
                segmentation[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
            }
        }
        [[Countly sharedInstance] recordEvent:key segmentation:segmentation count:count  sum:sum duration:duration];
        NSString *resultString = @"recordEvent for: ";
        resultString = [resultString stringByAppendingString: key];
        result(resultString);
        });
    }else if ([@"recordView" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* recordView = [command objectAtIndex:0];
        NSMutableDictionary *segments = [[NSMutableDictionary alloc] init];
        int il=(int)command.count;
        if(il > 2) {
            for(int i=1;i<il;i+=2){
                @try{
                    segments[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
                }
                @catch(NSException *exception){
                    COUNTLY_FLUTTER_LOG(@"recordView: Exception occured while parsing segments: %@", exception);
                }
            }
        }
        [Countly.sharedInstance recordView:recordView segmentation:segments];
        result(@"recordView Sent!");
        });
    }else if ([@"setLoggingEnabled" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            BOOL boolean = [[command objectAtIndex:0] boolValue];
            config.enableDebug = boolean;
            result(@"setLoggingEnabled!");
        });

    }else if ([@"setuserdata" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSDictionary* userData = [command objectAtIndex:0];

        NSString* name = userData[@"name"];
        NSString* username = userData[@"username"];
        NSString* email = userData[@"email"];
        NSString* organization = userData[@"organization"];
        NSString* phone = userData[@"phone"];
        NSString* picture = userData[@"picture"];
        NSString* picturePath = userData[@"picturePath"];
        NSString* gender = userData[@"gender"];
        NSString* byear = userData[@"byear"];

        if(name) {
            Countly.user.name = name;
        }
        if(username) {
            Countly.user.username = username;
        }
        if(email) {
            Countly.user.email = email;
        }
        if(organization) {
            Countly.user.organization = organization;
        }
        if(phone) {
            Countly.user.phone = phone;
        }
        if(picture) {
            Countly.user.pictureURL = picture;
        }
        if(gender) {
            Countly.user.gender = gender;
        }
        if(byear) {
            Countly.user.birthYear = @([byear integerValue]);
        }

        [Countly.user save];
        result(@"setuserdata!");
        });

    }else if ([@"beginSession" isEqualToString:call.method]) {
         dispatch_async(dispatch_get_main_queue(), ^ {
         [Countly.sharedInstance beginSession];
         result(@"beginSession!");
         });

     }else if ([@"updateSession" isEqualToString:call.method]) {
           dispatch_async(dispatch_get_main_queue(), ^ {
           [Countly.sharedInstance updateSession];
           result(@"updateSession!");
           });

     }else if ([@"endSession" isEqualToString:call.method]) {
           dispatch_async(dispatch_get_main_queue(), ^ {
           [Countly.sharedInstance endSession];
           result(@"endSession!");
           });

    }else if ([@"start" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance beginSession];
        result(@"start!");
        });

    }else if ([@"manualSessionHandling" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        config.manualSessionHandling = YES;
        result(@"manualSessionHandling!");
        });

    }else if ([@"stop" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance endSession];
        result(@"stop!");
        });

    }else if ([@"updateSessionPeriod" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        config.updateSessionPeriod = 15;
        result(@"updateSessionPeriod!");
        });

    }else if ([@"updateSessionInterval" isEqualToString:call.method]) {
             dispatch_async(dispatch_get_main_queue(), ^ {
             @try{
                 int sessionInterval = [[command objectAtIndex:0] intValue];
                 config.updateSessionPeriod = sessionInterval;
                 result(@"updateSessionInterval Success!");
             }
             @catch(NSException *exception){
                 COUNTLY_FLUTTER_LOG(@"Exception occurred at updateSessionInterval method: %@", exception);
             };
             });
    }else if ([@"eventSendThreshold" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        @try{
            int limit = [[command objectAtIndex:0] intValue];
            config.eventSendThreshold = limit;
            result(@"eventSendThreshold!");
        }
        @catch(NSException *exception){
            COUNTLY_FLUTTER_LOG(@"Exception occurred at eventSendThreshold method: %@", exception);
        };
        });

    }else if ([@"storedRequestsLimit" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        config.storedRequestsLimit = 1;
        result(@"storedRequestsLimit!");
        });

    }else if ([@"getCurrentDeviceId" isEqualToString:call.method]) {
        NSString* deviceId = [Countly.sharedInstance deviceID];
        result(deviceId);
    }else if ([@"getDeviceIdAuthor" isEqualToString:call.method]) {
        NSString* deviceIDType = [Countly.sharedInstance deviceIDType];
        result(deviceIDType);
    }else if ([@"changeDeviceId" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* newDeviceID = [command objectAtIndex:0];
        NSString* onServerString = [command objectAtIndex:1];

        if ([newDeviceID  isEqual: @"TemporaryDeviceID"]) {
            [Countly.sharedInstance setNewDeviceID:CLYTemporaryDeviceID onServer:NO];
        }else{
            if ([onServerString  isEqual: @"1"]) {
                [Countly.sharedInstance setNewDeviceID:newDeviceID onServer: YES];
            }else{
                [Countly.sharedInstance setNewDeviceID:newDeviceID onServer: NO];
            }
        }
        result(@"changeDeviceId!");
        });

    }else if ([@"setHttpPostForced" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            BOOL boolean = [[command objectAtIndex:0] boolValue];
            config.alwaysUsePOST = boolean;
            result(@"setHttpPostForced!");
        });

    }else if ([@"enableParameterTamperingProtection" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* salt = [command objectAtIndex:0];
        config.secretSalt = salt;
        result(@"enableParameterTamperingProtection!");
        });

    }else if ([@"startEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* eventName = [command objectAtIndex:0];
        [Countly.sharedInstance startEvent:eventName];
        result(@"startEvent!");
        });

    }else if ([@"endEvent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* key = [command objectAtIndex:0];
        NSString* countString = [command objectAtIndex:1];
        int count = [countString intValue];
        NSString* sumString = [command objectAtIndex:2];
        float sum = [sumString floatValue];
        NSMutableDictionary *segmentation = [[NSMutableDictionary alloc] init];

        if((int)command.count > 3){
            for(int i=3,il=(int)command.count;i<il;i+=2){
                segmentation[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
            }
        }
        [[Countly sharedInstance] endEvent:key segmentation:segmentation count:count  sum:sum];
        NSString *resultString = @"endEvent for: ";
        resultString = [resultString stringByAppendingString: key];
        result(resultString);
        });
    }else if ([@"setLocationInit" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString* countryCode = [command objectAtIndex:0];
            NSString* city = [command objectAtIndex:1];
            NSString* locationString = [command objectAtIndex:2];
            NSString* ipAddress = [command objectAtIndex:3];

            if(locationString != nil && ![locationString isEqualToString:@"null"] && [locationString containsString:@","]){
               @try{
                   NSArray *locationArray = [locationString componentsSeparatedByString:@","];
                   NSString* latitudeString = [locationArray objectAtIndex:0];
                   NSString* longitudeString = [locationArray objectAtIndex:1];

                   double latitudeDouble = [latitudeString doubleValue];
                   double longitudeDouble = [longitudeString doubleValue];
                   config.location = (CLLocationCoordinate2D){latitudeDouble,longitudeDouble};
               }
               @catch(NSException *exception){
                   COUNTLY_FLUTTER_LOG(@"Invalid location: %@", locationString);
               }
            }
            if(city != nil && ![city isEqualToString:@"null"]) {
               config.city = city;
            }
            if(countryCode != nil && ![countryCode isEqualToString:@"null"]) {
               config.ISOCountryCode = countryCode;
            }
            if(ipAddress != nil && ![ipAddress isEqualToString:@"null"]) {
               config.IP = ipAddress;
            }
             result(@"setLocationInit!");
        });

    }else if ([@"setLocation" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* latitudeString = [command objectAtIndex:0];
        NSString* longitudeString = [command objectAtIndex:1];

        if([@"null" isEqualToString:latitudeString]){
            latitudeString = nil;
        }
        if([@"null" isEqualToString:longitudeString]){
            longitudeString = nil;
        }

        if(latitudeString != nil && longitudeString != nil){
            @try{
                double latitudeDouble = [latitudeString doubleValue];
                double longitudeDouble = [longitudeString doubleValue];
                config.location = (CLLocationCoordinate2D){latitudeDouble,longitudeDouble};
            }
            @catch(NSException *execption){
                COUNTLY_FLUTTER_LOG(@"Invalid latitude or longitude.");
            }
        }
        result(@"setLocation!");
        });

    }else if ([@"enableCrashReporting" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        // config.features = @[CLYCrashReporting];
        [self addCountlyFeature:CLYCrashReporting];
        result(@"enableCrashReporting!");
        });

    }else if ([@"addCrashLog" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* record = [command objectAtIndex:0];
        [Countly.sharedInstance recordCrashLog: record];
        result(@"addCrashLog!");
        });

    }else if ([@"logException" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* execption = [command objectAtIndex:0];
        NSString* nonfatal = [command objectAtIndex:1];
        NSArray *nsException = [execption componentsSeparatedByString:@"\n"];

        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

        for(int i=2,il=(int)command.count;i<il;i+=2){
            dict[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        }
        [dict setObject:nonfatal forKey:@"nonfatal"];

        NSException* myException = [NSException exceptionWithName:@"Exception" reason:execption userInfo:dict];

        [Countly.sharedInstance recordHandledException:myException withStackTrace: nsException];
        result(@"logException!");
        });

    }else if ([@"setCustomCrashSegment" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        for(int i=0,il=(int)command.count;i<il;i+=2){
            dict[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        }
        config.crashSegmentation = dict;
        });
        result(@"setCustomCrashSegment!");
    }else if ([@"disablePushNotifications" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            enablePushNotifications = false;
        });
        result(@"disablePushNotifications!");
    }else if ([@"askForNotificationPermission" isEqualToString:call.method]) {
#if (TARGET_OS_IOS)
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
        dispatch_async(dispatch_get_main_queue(), ^ {
            [Countly.sharedInstance askForNotificationPermission];
        });
#endif
#endif
        result(@"askForNotificationPermission!");
    }else if ([@"pushTokenType" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        config.sendPushTokenAlways = YES;
        NSString* tokenType = [command objectAtIndex:0];
        if([tokenType isEqualToString: @"1"]){
            config.pushTestMode = @"CLYPushTestModeDevelopment";
        } else {
            config.pushTestMode = @"CLYPushTestModeTestFlightOrAdHoc";
        }
        result(@"pushTokenType!");
        });
    }else if ([@"registerForNotification" isEqualToString:call.method]) {
        COUNTLY_FLUTTER_LOG(@"registerForNotification");
        notificationListener = result;
        if(lastStoredNotification != nil){
            result([lastStoredNotification description]);
            lastStoredNotification = nil;
        }
    }else if ([@"userData_setProperty" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];

        [Countly.user set:keyName value:keyValue];
        [Countly.user save];

        result(@"userData_setProperty!");
        });

    }else if ([@"userData_increment" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];

        [Countly.user increment:keyName];
        [Countly.user save];

        result(@"userData_increment!");
        });

    }else if ([@"userData_incrementBy" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int keyValueInteger = [keyValue intValue];

        [Countly.user incrementBy:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];

        result(@"userData_incrementBy!");
        });

    }else if ([@"userData_multiply" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int keyValueInteger = [keyValue intValue];

        [Countly.user multiply:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];

        result(@"userData_multiply!");
        });

    }else if ([@"userData_saveMax" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int  keyValueInteger = [keyValue intValue];

        [Countly.user max:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];
        result(@"userData_saveMax!");
        });

    }else if ([@"userData_saveMin" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int keyValueInteger = [keyValue intValue];

        [Countly.user min:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];

        result(@"userData_saveMin!");
        });

    }else if ([@"userData_setOnce" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];

        [Countly.user setOnce:keyName value:keyValue];
        [Countly.user save];

        result(@"userData_setOnce!");
        });

    }else if ([@"userData_pushUniqueValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* type = [command objectAtIndex:0];
        NSString* pushUniqueValueString = [command objectAtIndex:1];

        [Countly.user pushUnique:type value:pushUniqueValueString];
        [Countly.user save];

        result(@"userData_pushUniqueValue!");
        });

    }else if ([@"userData_pushValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* type = [command objectAtIndex:0];
        NSString* pushValue = [command objectAtIndex:1];

        [Countly.user push:type value:pushValue];
        [Countly.user save];

        result(@"userData_pushValue!");
        });

    }else if ([@"userData_pullValue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* type = [command objectAtIndex:0];
        NSString* pullValue = [command objectAtIndex:1];

        [Countly.user pull:type value:pullValue];
        [Countly.user save];

        result(@"userData_pullValue!");
        });

    //setRequiresConsent
    }else if ([@"setRequiresConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        BOOL consentFlag = [[command objectAtIndex:0] boolValue];
        config.requiresConsent = consentFlag;
        result(@"setRequiresConsent!");
        });

    }else if ([@"giveConsentInit" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        config.consents = command;
        result(@"giveConsentInit!");
        });

    }else if ([@"giveConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance giveConsentForFeatures:command];
        result(@"giveConsent!");
        });

    }else if ([@"removeConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsent!");
        });

    }else if ([@"giveAllConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance giveConsentForFeature:CLYConsentLocation];
        [Countly.sharedInstance giveConsentForAllFeatures];
        result(@"giveAllConsent!");
        });
    }else if ([@"removeAllConsent" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance cancelConsentForAllFeatures];
        result(@"removeAllConsent!");
        });
    }else if ([@"setOptionalParametersForInitialization" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* city = [command objectAtIndex:0];
        NSString* country = [command objectAtIndex:1];

        NSString* latitudeString = [command objectAtIndex:2];
        NSString* longitudeString = [command objectAtIndex:3];
        NSString* ipAddress = [command objectAtIndex:4];

        if([@"null" isEqualToString:city]){
            city = nil;
        }
        if([@"null" isEqualToString:country]){
            country = nil;
        }
        if([@"null" isEqualToString:latitudeString]){
            latitudeString = nil;
        }
        if([@"null" isEqualToString:longitudeString]){
            longitudeString = nil;
        }
        if([@"null" isEqualToString:ipAddress]){
            ipAddress = nil;
        }
        CLLocationCoordinate2D location;
        if(latitudeString != nil && longitudeString != nil){
            @try{
                double latitudeDouble = [latitudeString doubleValue];
                double longitudeDouble = [longitudeString doubleValue];
                
                location = (CLLocationCoordinate2D){latitudeDouble,longitudeDouble};
            }
            @catch(NSException *execption){
                COUNTLY_FLUTTER_LOG(@"Invalid latitude or longitude.");
            }
        }
        [Countly.sharedInstance recordLocation:location city:city ISOCountryCode:country IP:ipAddress];
        result(@"setOptionalParametersForInitialization!");
        });

    }else if ([@"setRemoteConfigAutomaticDownload" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        config.enableRemoteConfig = YES;
        config.remoteConfigCompletionHandler = ^(NSError * error)
        {
            if (!error){
                result(@"Success!");
            } else {
                result([@"Error :" stringByAppendingString: error.localizedDescription]);
            }
        };
        });

    }else if ([@"remoteConfigUpdate" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [Countly.sharedInstance updateRemoteConfigWithCompletionHandler:^(NSError * error)
         {
             if (!error){
                 result(@"Success!");
             } else {
                 result([@"Error :" stringByAppendingString: error.localizedDescription]);
             }
         }];
        });

    }else if ([@"updateRemoteConfigForKeysOnly" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSMutableArray *randomSelection = [[NSMutableArray alloc] init];
        for (int i = 0; i < (int)command.count; i++){
            [randomSelection addObject:[command objectAtIndex:i]];
        }
        NSArray *keysOnly = [randomSelection copy];

        // NSArray * keysOnly[] = {};
        // for(int i=0,il=(int)command.count;i<il;i++){
        //     keysOnly[i] = [command objectAtIndex:i];
        // }
        [Countly.sharedInstance updateRemoteConfigOnlyForKeys: keysOnly completionHandler:^(NSError * error)
         {
             if (!error){
                result(@"Success!");
             } else {
                 result([@"Error :" stringByAppendingString: error.localizedDescription]);
             }
         }];
        });

    }else if ([@"updateRemoteConfigExceptKeys" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSMutableArray *randomSelection = [[NSMutableArray alloc] init];
        for (int i = 0; i < (int)command.count; i++){
            [randomSelection addObject:[command objectAtIndex:i]];
        }
        NSArray *exceptKeys = [randomSelection copy];

        // NSArray * exceptKeys[] = {};
        // for(int i=0,il=(int)command.count;i<il;i++){
        //     exceptKeys[i] = [command objectAtIndex:i];
        // }
        [Countly.sharedInstance updateRemoteConfigExceptForKeys: exceptKeys completionHandler:^(NSError * error)
         {
             if (!error){
                 result(@"Success!");
             } else {
                 result([@"Error :" stringByAppendingString: error.localizedDescription]);
             }
         }];
        });

    }else if ([@"remoteConfigClearValues" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        [CountlyRemoteConfig.sharedInstance clearCachedRemoteConfig];
        result(@"Success!");
        });

    }else if ([@"getRemoteConfigValueForKey" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString* key = [command objectAtIndex:0];
            id value = [Countly.sharedInstance remoteConfigValueForKey:key];
            if(!value){
                value = @"Default Value";
            }
            NSString *theType = NSStringFromClass([value class]);
            if([theType isEqualToString:@"NSTaggedPointerString"] || [theType isEqualToString:@"__NSCFConstantString"]){
                result(value);
            }else{
                result([value stringValue]);
            }
        });
    }else if ([@"presentRatingWidgetWithID" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* widgetId = [command objectAtIndex:0];
         [Countly.sharedInstance presentFeedbackWidgetWithID:widgetId completionHandler:^(NSError* error){

            NSString* errorStr = nil;
            if (error){
                errorStr = error.localizedDescription;
                NSString *theError = [@"presentRatingWidgetWithID failed: " stringByAppendingString: errorStr;
                result(theError);
            }
            else{
                result(@"presentRatingWidgetWithID success.");
            }
            [_channel invokeMethod:@"ratingWidgetCallback" arguments: errorStr];
        }];
        });
    }else if ([@"setStarRatingDialogTexts" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString* starRatingTextMessage = [command objectAtIndex:1];
            config.starRatingMessage = starRatingTextMessage;
        });
        result(@"setStarRatingDialogTexts: success");
    }else if ([@"askForStarRating" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [Countly.sharedInstance askForStarRating:^(NSInteger rating){
                result([NSString stringWithFormat: @"Rating:%d", (int)rating]);
            }];
        });
    }else if ([@"getAvailableFeedbackWidgets" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [Countly.sharedInstance getFeedbackWidgets:^(NSArray<CountlyFeedbackWidget *> * _Nonnull feedbackWidgets, NSError * _Nonnull error) {
                feedbackWidgetList = [NSArray arrayWithArray:feedbackWidgets];
                NSMutableArray* feedbackWidgetsArray = [NSMutableArray arrayWithCapacity:feedbackWidgets.count];
                  for (CountlyFeedbackWidget* retrievedWidget in feedbackWidgets) {
                      NSMutableDictionary* feedbackWidget = [NSMutableDictionary dictionaryWithCapacity:3];
                      feedbackWidget[@"id"] = retrievedWidget.ID;
                      feedbackWidget[@"type"] = retrievedWidget.type;
                      feedbackWidget[@"name"] = retrievedWidget.name;
                      [feedbackWidgetsArray addObject:feedbackWidget];
                  }
                result(feedbackWidgetsArray);
            }];
        });
    } else if ([@"presentFeedbackWidget" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* widgetId = [command objectAtIndex:0];
        CountlyFeedbackWidget* feedbackWidget = [self getFeedbackWidget:widgetId];
        if(feedbackWidget == nil) {
            NSString* errorMessage = [NSString stringWithFormat:@"No feedbackWidget is found against widget Id : '%@', always call 'getFeedbackWidgets' to get updated list of feedback widgets.", widgetId];
              COUNTLY_FLUTTER_LOG(errorMessage);
              result(errorMessage);
        }
        else {
            [feedbackWidget presentWithAppearBlock:^{
                            [_channel invokeMethod:@"widgetShown" arguments:nil];
                            result(@"appeared");
                        } andDismissBlock:^{
                            [_channel invokeMethod:@"widgetClosed" arguments:nil];
                            result(@"dismissed");
                        }];
        }
            
        });
    } else if ([@"getFeedbackWidgetData" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSString* widgetId = [command objectAtIndex:0];
        CountlyFeedbackWidget* feedbackWidget = [self getFeedbackWidget:widgetId];
            if(feedbackWidget == nil) {
                NSString* errorMessage = [NSString stringWithFormat:@"No feedbackWidget is found against widget Id : '%@', always call 'getFeedbackWidgets' to get updated list of feedback widgets.", widgetId];
                  COUNTLY_FLUTTER_LOG(errorMessage);
                  result(errorMessage);
            }
            else {
                [feedbackWidget getWidgetData:^(NSDictionary * _Nullable widgetData, NSError * _Nullable error) {
                    if (error){
                        NSString *theError = [@"getFeedbackWidgetData failed: " stringByAppendingString: error.localizedDescription];
                        result(theError);
                    }
                    else{
                        result(widgetData);
                    }
                }];
            }
        });
    } else if ([@"reportFeedbackWidgetManually" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
        NSArray* widgetInfo = [command objectAtIndex:0];
//        NSDictionary* widgetData = [command objectAtIndex:1];
        NSDictionary* widgetResult = [command objectAtIndex:2];
            
        NSString* widgetId = [widgetInfo objectAtIndex:0];
            
        CountlyFeedbackWidget* feedbackWidget = [self getFeedbackWidget:widgetId];
            if(feedbackWidget == nil) {
                NSString* errorMessage = [NSString stringWithFormat:@"No feedbackWidget is found against widget Id : '%@', always call 'getFeedbackWidgets' to get updated list of feedback widgets.", widgetId];
                  COUNTLY_FLUTTER_LOG(errorMessage);
                  result(errorMessage);
            }
            else {
                [feedbackWidget recordResult:widgetResult];
            }
        });
    }else if ([@"replaceAllAppKeysInQueueWithCurrentAppKey" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [Countly.sharedInstance replaceAllAppKeysInQueueWithCurrentAppKey];
        });
        result(@"requestQueueOverwriteAppKeys: success");
    } else if ([@"removeDifferentAppKeysFromQueue" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [Countly.sharedInstance removeDifferentAppKeysFromQueue];
        });
        result(@"requestQueueEraseAppKeysRequests: success");
    } else if ([@"startTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString* traceKey = [command objectAtIndex:0];
            [Countly.sharedInstance startCustomTrace: traceKey];
        });
        result(@"startTrace: success");
    } else if ([@"cancelTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString* traceKey = [command objectAtIndex:0];
            [Countly.sharedInstance cancelCustomTrace: traceKey];
        });
        result(@"cancelTrace: success");
    } else if ([@"clearAllTraces" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [Countly.sharedInstance clearAllCustomTraces];
        });
        result(@"clearAllTrace: success");
    } else if ([@"endTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSString* traceKey = [command objectAtIndex:0];
            NSMutableDictionary *metrics = [[NSMutableDictionary alloc] init];
            for(int i=1,il=(int)command.count;i<il;i+=2){
                @try{
                    metrics[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
                }
                @catch(NSException *exception){
                    COUNTLY_FLUTTER_LOG(@"Exception occurred while parsing metric: %@", exception);
                }
            }
            [Countly.sharedInstance endCustomTrace: traceKey metrics: metrics];
        });
        result(@"endTrace: success");
    } else if ([@"recordNetworkTrace" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            @try{
                NSString* networkTraceKey = [command objectAtIndex:0];
                int responseCode = [[command objectAtIndex:1] intValue];
                int requestPayloadSize = [[command objectAtIndex:2] intValue];
                int responsePayloadSize = [[command objectAtIndex:3] intValue];
                long long startTime = [[command objectAtIndex:4] longLongValue];
                long long endTime = [[command objectAtIndex:5] longLongValue];
                [Countly.sharedInstance recordNetworkTrace: networkTraceKey requestPayloadSize: requestPayloadSize responsePayloadSize: responsePayloadSize responseStatusCode: responseCode startTime: startTime endTime: endTime];
            }
            @catch(NSException *exception){
                COUNTLY_FLUTTER_LOG(@"Exception occured at recordNetworkTrace method: %@", exception);
            }
        });
        result(@"recordNetworkTrace: success");
    } else if ([@"enableApm" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            config.enablePerformanceMonitoring = YES;
        });
        result(@"enableApm: success");
   
    } else if ([@"throwNativeException" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSException *e = [NSException exceptionWithName:@"Native Exception Crash!" reason:@"Throw Native Exception..." userInfo:nil];
            @throw e;
        });
    }else if([@"recordIndirectAttribution" isEqualToString:call.method]) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSDictionary* attributionValues = [command objectAtIndex:0];
            NSString* IDFAKey = @"idfa";
            NSString* attributionID = [attributionValues objectForKey:IDFAKey];
            if (attributionID) {
                if(CountlyCommon.sharedInstance.hasStarted) {
                  [Countly.sharedInstance recordAttributionID: attributionID];
                }
                else {
                  config.attributionID = attributionID;
                }
            }
        });
    }else if ([@"appLoadingFinished" isEqualToString:call.method]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [Countly.sharedInstance appLoadingFinished];
            });
            result(@"appLoadingFinished: success");
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (CountlyFeedbackWidget*)getFeedbackWidget:(NSString*)widgetId
{
  if(feedbackWidgetList == nil) {
    return nil;
  }
  for (CountlyFeedbackWidget* feedbackWidget in feedbackWidgetList) {
    if([feedbackWidget.ID isEqual:widgetId]) {
      return feedbackWidget;
    }
  }
  return nil;
}

- (void)populateConfig:(NSDictionary*)_config
{
    @try{
        NSString* appKey = _config[@"appKey"];
        if(appKey) {
            config.appKey = appKey;
        }
        NSString* host = _config[@"serverURL"];
        if(host) {
            config.host = host;
        }
        NSString* deviceID = _config[@"deviceID"];
        if(deviceID){
            if ([@"TemporaryDeviceID" isEqualToString:deviceID]) {
                config.deviceID = CLYTemporaryDeviceID;
            } else {
                config.deviceID = deviceID;
            }
        }
        NSNumber* loggingEnabled = _config[@"loggingEnabled"];
        if(loggingEnabled) {
            config.enableDebug = [loggingEnabled boolValue];
        }
        NSNumber* httpPostForced = _config[@"httpPostForced"];
        if(httpPostForced) {
            config.alwaysUsePOST = [httpPostForced boolValue];
        }
        NSNumber* shouldRequireConsent = _config[@"shouldRequireConsent"];
        if(shouldRequireConsent) {
            config.requiresConsent = [shouldRequireConsent boolValue];
        }

        NSNumber* eventQueueSizeThreshold = _config[@"eventQueueSizeThreshold"];
        if(eventQueueSizeThreshold) {
            config.eventSendThreshold = [eventQueueSizeThreshold intValue];
        }
        NSNumber* sessionUpdateTimerDelay = _config[@"sessionUpdateTimerDelay"];
        if(sessionUpdateTimerDelay) {
            config.updateSessionPeriod = [sessionUpdateTimerDelay intValue];
        }
        NSString* salt = _config[@"tamperingProtectionSalt"];
        if(salt) {
            config.secretSalt = salt;
        }

        NSDictionary* crashSegmentation = _config[@"customCrashSegment"];
        if(crashSegmentation) {
            config.crashSegmentation = crashSegmentation;
        }
        NSArray* consents = _config[@"consents"];
        if(consents) {
            config.consents = consents;
        }
        NSString* starRatingTextMessage = _config[@"starRatingTextMessage"];
        if(starRatingTextMessage) {
            config.starRatingMessage = starRatingTextMessage;
        }
        NSNumber* recordAppStartTime = _config[@"recordAppStartTime"];
        if(recordAppStartTime) {
            config.enablePerformanceMonitoring = [recordAppStartTime boolValue];
        }
        NSNumber* enableUnhandledCrashReporting = _config[@"enableUnhandledCrashReporting"];
        if(enableUnhandledCrashReporting && [enableUnhandledCrashReporting boolValue]) {
            [self addCountlyFeature:CLYCrashReporting];
        }

        NSNumber* maxRequestQueueSize = _config[@"maxRequestQueueSize"];
        if(maxRequestQueueSize) {
            config.storedRequestsLimit = [maxRequestQueueSize intValue];
        }

        NSNumber* manualSessionEnabled = _config[@"manualSessionEnabled"];
        if(manualSessionEnabled && [manualSessionEnabled boolValue]) {
            config.manualSessionHandling = YES;
        }
        NSNumber* enableRemoteConfigAutomaticDownload = _config[@"enableRemoteConfigAutomaticDownload"];
        if(enableRemoteConfigAutomaticDownload)
        {
            config.enableRemoteConfig = [enableRemoteConfigAutomaticDownload boolValue];
            config.remoteConfigCompletionHandler = ^(NSError * error)
            {
                NSString* errorStr = nil;
                if(error) {
                    errorStr = error.localizedDescription;
                }
                [_channel invokeMethod:@"remoteConfigCallback" arguments:errorStr];
            };
        }

        NSDictionary* location = _config[@"location"];
        if(location) {
            [self setLocation:location];
        }

         NSDictionary* attributionValues = _config[@"attributionValues"];
         NSString* IDFAKey = @"idfa";
         NSString* attributionID = [attributionValues objectForKey:IDFAKey];
        if (attributionID) {
            config.attributionID = attributionID;
        }
    }
    @catch(NSException *exception){
       COUNTLY_FLUTTER_LOG(@"populateConfig, Unable to parse Config object: %@", exception);
    }

}

-(void) setLocation:(NSDictionary*)location
{
    NSString* gpsCoordinates =  location[@"gpsCoordinates"];
    if(gpsCoordinates && [gpsCoordinates containsString:@","]){
       @try{
           NSArray *locationArray = [gpsCoordinates componentsSeparatedByString:@","];
           NSString* latitudeString = [locationArray objectAtIndex:0];
           NSString* longitudeString = [locationArray objectAtIndex:1];

           double latitudeDouble = [latitudeString doubleValue];
           double longitudeDouble = [longitudeString doubleValue];
           config.location = (CLLocationCoordinate2D){latitudeDouble,longitudeDouble};
       }
       @catch(NSException *exception){
           COUNTLY_FLUTTER_LOG(@"Invalid location: %@", gpsCoordinates);
       }
    }
    NSString* city =  location[@"city"];
    if(city) {
       config.city = city;
    }
    NSString* countryCode =  location[@"countryCode"];
    if(countryCode) {
       config.ISOCountryCode = countryCode;
    }
    
    NSString* ipAddress =  location[@"ipAddress"];
    if(ipAddress) {
       config.IP = ipAddress;
    }
}

+ (void)onNotification: (NSDictionary *) notificationMessage{
    COUNTLY_FLUTTER_LOG(@"Notification received");
    COUNTLY_FLUTTER_LOG(@"The notification %@", notificationMessage);
    if(notificationMessage && notificationListener != nil){
        notificationListener([NSString stringWithFormat:@"%@",notificationMessage]);
    }else{
        lastStoredNotification = notificationMessage;
    }
    if(notificationMessage){
        if(notificationIDs == nil){
            notificationIDs = [[NSMutableArray alloc] init];
        }
        NSDictionary* countlyPayload = notificationMessage[@"c"];
        NSString *notificationID = countlyPayload[@"i"];
        [notificationIDs insertObject:notificationID atIndex:[notificationIDs count]];
    }
}
- (void)recordPushAction
{
    for(int i=0,il = (int) notificationIDs.count;i<il;i++){
        NSString *notificationID = notificationIDs[i];
        NSDictionary* segmentation =
        @{
            @"i": notificationID,
            @"b": @(0)
        };
        [Countly.sharedInstance recordEvent:@"[CLY]_push_action" segmentation: segmentation];
    }
    
    [notificationIDs removeAllObjects];
}

- (void)addCountlyFeature:(CLYFeature)feature
{
    if(countlyFeatures == nil) {
        countlyFeatures = [[NSMutableArray alloc] init];
    }
    if(![countlyFeatures containsObject:feature]) {
        [countlyFeatures addObject:feature];
        config.features = countlyFeatures;
    }
}

- (void)removeCountlyFeature:(CLYFeature)feature
{
    if(countlyFeatures == nil) {
        return;
    }
    if(![countlyFeatures containsObject:feature]) {
        [countlyFeatures removeObject:feature];
        config.features = countlyFeatures;
    }
}

void CountlyFlutterInternalLog(NSString *format, ...)
{
    if (!config.enableDebug)
        return;

    va_list args;
    va_start(args, format);

    NSString* logString = [NSString.alloc initWithFormat:format arguments:args];
    NSLog(@"[CountlyFlutterPlugin] %@", logString);

    va_end(args);
}
@end
