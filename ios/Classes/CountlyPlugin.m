#import "CountlyPlugin.h"
#import "Countly.h"
#import "CountlyConfig.h"
#import "CountlyDeviceInfo.h"
#import "CountlyRemoteConfig.h"


@implementation CountlyPlugin

CountlyConfig* config = nil;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"countly"
            binaryMessenger:[registrar messenger]];
  CountlyPlugin* instance = [[CountlyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
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


        NSString* serverurl = [command  objectAtIndex:0];
        NSString* appkey = [command objectAtIndex:1];
        NSString* deviceID = @"";

        config.appKey = appkey;
        config.host = serverurl;

        if(command.count == 3){
            deviceID = [command objectAtIndex:2];
            config.deviceID = deviceID;
        }

        if (serverurl != nil && [serverurl length] > 0) {
            [[Countly sharedInstance] startWithConfig:config];
            result(@"initialized");
        } else {
            result(@"Errorabc");
        }

        // config.deviceID = deviceID; doesn't work so applied at patch temporarly.
        if(command.count == 3){
            deviceID = [command objectAtIndex:2];
            [Countly.sharedInstance setNewDeviceID:deviceID onServer:YES];   //replace and merge on server
        }
    }else if ([@"recordEvent" isEqualToString:call.method]) {
        NSString* key = [command objectAtIndex:0];
        NSString* countString = [command objectAtIndex:1];
        int count = [countString intValue];
        NSString* sumString = [command objectAtIndex:2];
        float sum = [sumString floatValue];
        NSMutableDictionary *segmentation = [[NSMutableDictionary alloc] init];

        for(int i=4,il=(int)command.count;i<il;i+=2){
            segmentation[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        }
        [[Countly sharedInstance] recordEvent:key segmentation:segmentation count:count  sum:sum];
        NSString *resultString = @"recordEvent for: ";
        resultString = [resultString stringByAppendingString: key];
        result(resultString);
        // NSString* eventType = [command objectAtIndex:0];
        // if (eventType != nil && [eventType length] > 0) {
        //     if ([eventType  isEqual: @"event"]) {
        //         NSString* eventName = [command objectAtIndex:1];
        //         NSString* countString = [command objectAtIndex:2];
        //         int countInt = [countString intValue];
        //         [[Countly sharedInstance] recordEvent:eventName count:countInt];
        //         result(@"event sent!");

        //     }else if ([eventType  isEqual: @"eventWithSum"]){
        //         NSString* eventName = [command objectAtIndex:1];
        //         NSString* countString = [command objectAtIndex:2];
        //         int countInt = [countString intValue];
        //         NSString* sumString = [command objectAtIndex:3];
        //         float sumFloat = [sumString floatValue];
        //         [[Countly sharedInstance] recordEvent:eventName count:countInt  sum:sumFloat];
        //         result(@"eventWithSum sent!");
        //     }
        //     else if ([eventType  isEqual: @"eventWithSegment"]){
        //         NSString* eventName = [command objectAtIndex:1];
        //         NSString* countString = [command objectAtIndex:2];
        //         int countInt = [countString intValue];
        //         NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

        //         for(int i=3,il=(int)command.count;i<il;i+=2){
        //             dict[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        //         }
        //         [[Countly sharedInstance] recordEvent:eventName segmentation:dict count:countInt];
        //         result(@"eventWithSegment sent!");
        //     }
        //     else if ([eventType  isEqual: @"eventWithSumSegment"]){
        //         NSString* eventName = [command objectAtIndex:1];
        //         NSString* countString = [command objectAtIndex:2];
        //         int countInt = [countString intValue];
        //         NSString* sumString = [command objectAtIndex:3];
        //         float sumFloat = [sumString floatValue];
        //         NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

        //         for(int i=4,il=(int)command.count;i<il;i+=2){
        //             dict[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        //         }
        //         [[Countly sharedInstance] recordEvent:eventName segmentation:dict count:countInt  sum:sumFloat];
        //         result(@"eventWithSegment sent!");
        //     }
        //     else{
        //         result(@"none cases!");
        //     }
        // } else {
        //     result(@"default!");
        // }
    }else if ([@"recordView" isEqualToString:call.method]) {
        NSString* recordView = [command objectAtIndex:0];
        [Countly.sharedInstance recordView:recordView];
        result(@"recordView Sent!");
    }else if ([@"setloggingenabled" isEqualToString:call.method]) {
        config.enableDebug = YES;
        result(@"setloggingenabled!");

    }else if ([@"setuserdata" isEqualToString:call.method]) {
        NSString* name = [command objectAtIndex:0];
        NSString* username = [command objectAtIndex:1];
        NSString* email = [command objectAtIndex:2];
        NSString* organization = [command objectAtIndex:3];
        NSString* phone = [command objectAtIndex:4];
        NSString* picture = [command objectAtIndex:5];
        //NSString* picturePath = [command objectAtIndex:6];
        NSString* gender = [command objectAtIndex:7];
        NSString* byear = [command objectAtIndex:8];

        Countly.user.name = name;
        Countly.user.username = username;
        Countly.user.email = email;
        Countly.user.organization = organization;
        Countly.user.phone = phone;
        Countly.user.pictureURL = picture;
        Countly.user.gender = gender;
        Countly.user.birthYear = @([byear integerValue]);

        [Countly.user save];
        result(@"setuserdata!");

    }else if ([@"getDeviceID" isEqualToString:call.method]) {
        NSString* deviceID = Countly.sharedInstance.deviceID;
        result(@"default!");

    }else if ([@"sendRating" isEqualToString:call.method]) {
        NSString* ratingString = [command objectAtIndex:0];
        int rating = [ratingString intValue];
        NSString* const kCountlySRKeyPlatform       = @"platform";
        NSString* const kCountlySRKeyAppVersion     = @"app_version";
        NSString* const kCountlySRKeyRating         = @"rating";
        NSString* const kCountlyReservedEventStarRating = @"[CLY]_star_rating";

        if (rating != 0)
        {
            NSDictionary* segmentation =
            @{
              kCountlySRKeyPlatform: CountlyDeviceInfo.osName,
              kCountlySRKeyAppVersion: CountlyDeviceInfo.appVersion,
              kCountlySRKeyRating: @(rating)
              };
//            [Countly.sharedInstance recordReservedEvent:kCountlyReservedEventStarRating segmentation:segmentation];
        }
        result(@"sendRating!");

    }else if ([@"start" isEqualToString:call.method]) {
        [Countly.sharedInstance beginSession];
        result(@"start!");

    }else if ([@"update" isEqualToString:call.method]) {
        [Countly.sharedInstance updateSession];
        result(@"update!");

    }else if ([@"stop" isEqualToString:call.method]) {
        [Countly.sharedInstance endSession];
        result(@"stop!");

    }else if ([@"changeDeviceId" isEqualToString:call.method]) {
        NSString* newDeviceID = [command objectAtIndex:0];
        NSString* onServerString = [command objectAtIndex:1];

        if ([onServerString  isEqual: @"true"]) {
            [Countly.sharedInstance setNewDeviceID:newDeviceID onServer: YES];
        }else{
            [Countly.sharedInstance setNewDeviceID:newDeviceID onServer: NO];
        }

        result(@"changeDeviceId!");

    }else if ([@"setHttpPostForced" isEqualToString:call.method]) {
        config.alwaysUsePOST = YES;
        result(@"setHttpPostForced!");

    }else if ([@"enableParameterTamperingProtection" isEqualToString:call.method]) {
        NSString* salt = [command objectAtIndex:0];
        config.secretSalt = salt;
        result(@"enableParameterTamperingProtection!");

    }else if ([@"startEvent" isEqualToString:call.method]) {
        NSString* eventName = [command objectAtIndex:0];
        [Countly.sharedInstance startEvent:eventName];
        result(@"startEvent!");

    }else if ([@"endEvent" isEqualToString:call.method]) {

        NSString* key = [command objectAtIndex:0];
        NSString* countString = [command objectAtIndex:1];
        int count = [countString intValue];
        NSString* sumString = [command objectAtIndex:2];
        float sum = [sumString floatValue];
        NSMutableDictionary *segmentation = [[NSMutableDictionary alloc] init];

        for(int i=4,il=(int)command.count;i<il;i+=2){
            segmentation[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        }
        [[Countly sharedInstance] endEvent:key segmentation:segmentation count:count  sum:sum];
        NSString *resultString = @"endEvent for: ";
        resultString = [resultString stringByAppendingString: key];
        result(resultString);

        // NSString* eventType = [command objectAtIndex:0];

        // if ([eventType  isEqual: @"event"]) {
        //     NSString* eventName = [command objectAtIndex:1];
        //     [Countly.sharedInstance endEvent:eventName];
        //     result(@"event sent!");
        // }
        // else if ([eventType  isEqual: @"eventWithSum"]){
        //     NSString* eventName = [command objectAtIndex:1];
        //     NSString* countString = [command objectAtIndex:2];
        //     int countInt = [countString intValue];
        //     NSString* sumString = [command objectAtIndex:3];
        //     int sumInt = [sumString intValue];
        //     NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        //     [Countly.sharedInstance endEvent:eventName segmentation:dict count:countInt sum:sumInt];
        //     result(@"eventWithSum sent!");
        // }
        // else if ([eventType  isEqual: @"eventWithSegment"]){
        //     NSString* eventName = [command objectAtIndex:1];
        //     NSString* countString = [command objectAtIndex:2];
        //     int countInt = [countString intValue];
        //     NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        //     for(int i=4,il=(int)command.count;i<il;i+=2){
        //         dict[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        //     }
        //     [Countly.sharedInstance endEvent:eventName segmentation:dict count:countInt sum:0];
        //     result(@"eventWithSegment sent!");
        // }
        // else if ([eventType  isEqual: @"eventWithSumSegment"]){
        //     NSString* eventName = [command objectAtIndex:1];
        //     NSString* countString = [command objectAtIndex:2];
        //     int countInt = [countString intValue];
        //     NSString* sumString = [command objectAtIndex:3];
        //     int sumInt = [sumString intValue];
        //     NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        //     for(int i=4,il=(int)command.count;i<il;i+=2){
        //         dict[[command objectAtIndex:i]] = [command objectAtIndex:i+1];
        //     }
        //     [Countly.sharedInstance endEvent:eventName segmentation:dict count:countInt sum:sumInt];
        //     result(@"eventWithSumSegment sent!");
        // }
        // else{
        //     result(@"none cases!");
        // }

    }else if ([@"setLocation" isEqualToString:call.method]) {
        NSString* latitudeString = [command objectAtIndex:0];
        NSString* longitudeString = [command objectAtIndex:1];

        double latitudeDouble = [latitudeString doubleValue];
        double longitudeDouble = [longitudeString doubleValue];

        config.location = (CLLocationCoordinate2D){latitudeDouble,longitudeDouble};

        result(@"setLocation!");

    }else if ([@"enableCrashReporting" isEqualToString:call.method]) {
        config.features = @[CLYCrashReporting];
        result(@"enableCrashReporting!");

    }else if ([@"addCrashLog" isEqualToString:call.method]) {
        NSString* record = [command objectAtIndex:0];
        [Countly.sharedInstance recordCrashLog: record];
        result(@"addCrashLog!");

    }else if ([@"logException" isEqualToString:call.method]) {
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

    }else if ([@"sendPushToken" isEqualToString:call.method]) {
        NSString* token = [command objectAtIndex:0];
        int messagingMode = [[command objectAtIndex:1] intValue];

        [Countly.sharedInstance sendPushToken:token messagingMode: messagingMode];
        result(@"sendPushToken!");

    }else if ([@"userData_setProperty" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];

        [Countly.user set:keyName value:keyValue];
        [Countly.user save];

        result(@"userData_setProperty!");

    }else if ([@"userData_increment" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];

        [Countly.user increment:keyName];
        [Countly.user save];

        result(@"userData_increment!");

    }else if ([@"userData_incrementBy" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int keyValueInteger = [keyValue intValue];

        [Countly.user incrementBy:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];

        result(@"userData_incrementBy!");

    }else if ([@"userData_multiply" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int keyValueInteger = [keyValue intValue];

        [Countly.user multiply:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];

        result(@"userData_multiply!");

    }else if ([@"userData_saveMax" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int  keyValueInteger = [keyValue intValue];

        [Countly.user max:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];
        result(@"userData_saveMax!");

    }else if ([@"userData_saveMin" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];
        int keyValueInteger = [keyValue intValue];

        [Countly.user min:keyName value:[NSNumber numberWithInt:keyValueInteger]];
        [Countly.user save];

        result(@"userData_saveMin!");

    }else if ([@"userData_setOnce" isEqualToString:call.method]) {
        NSString* keyName = [command objectAtIndex:0];
        NSString* keyValue = [command objectAtIndex:1];

        [Countly.user setOnce:keyName value:keyValue];
        [Countly.user save];

        result(@"userData_setOnce!");

    }else if ([@"userData_pushUniqueValue" isEqualToString:call.method]) {
        NSString* type = [command objectAtIndex:0];
        NSString* pushUniqueValueString = [command objectAtIndex:1];

        [Countly.user pushUnique:type value:pushUniqueValueString];
        [Countly.user save];

        result(@"userData_pushUniqueValue!");

    }else if ([@"userData_pushValue" isEqualToString:call.method]) {
        NSString* type = [command objectAtIndex:0];
        NSString* pushValue = [command objectAtIndex:1];

        [Countly.user push:type value:pushValue];
        [Countly.user save];

        result(@"userData_pushValue!");

    }else if ([@"userData_pullValue" isEqualToString:call.method]) {
        NSString* type = [command objectAtIndex:0];
        NSString* pullValue = [command objectAtIndex:1];

        [Countly.user pull:type value:pullValue];
        [Countly.user save];

        result(@"userData_pullValue!");

    //setRequiresConsent
    }else if ([@"setRequiresConsent" isEqualToString:call.method]) {
        BOOL consentFlag = [[command objectAtIndex:0] boolValue];
        config.requiresConsent = consentFlag;
        result(@"setRequiresConsent!");

    }else if ([@"giveConsent" isEqualToString:call.method]) {
        [Countly.sharedInstance giveConsentForFeatures:command];
        result(@"giveConsent!");

    }else if ([@"removeConsent" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsent!");

    }else if ([@"giveAllConsent" isEqualToString:call.method]) {
        [Countly.sharedInstance giveConsentForAllFeatures];
        result(@"giveAllConsent!");

    }else if ([@"removeAllConsent" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForAllFeatures];
        result(@"removeAllConsent!");


    }else if ([@"giveConsentSession" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentSession!");

    }else if ([@"giveConsentEvents" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentEvents!");

    }else if ([@"giveConsentViews" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentViews!");

    }else if ([@"giveConsentLocation" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentLocation!");

    }else if ([@"giveConsentcrashes" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentcrashes!");

    }else if ([@"giveConsentattribution" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentattribution!");

    }else if ([@"giveConsentusers" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentusers!");

    }else if ([@"giveConsentpush" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentpush!");

    }else if ([@"giveConsentstarRating" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"giveConsentstarRating!");    


    }else if ([@"removeConsentSession" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentSession!");

    }else if ([@"removeConsentEvents" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentEvents!");

    }else if ([@"removeConsentViews" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentViews!");

    }else if ([@"removeConsentLocation" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentLocation!");

    }else if ([@"removeConsentcrashes" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentcrashes!");

    }else if ([@"removeConsentattribution" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentattribution!");

    }else if ([@"removeConsentusers" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentusers!");

    }else if ([@"removeConsentpush" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentpush!");
        
    }else if ([@"removeConsentstarRating" isEqualToString:call.method]) {
        [Countly.sharedInstance cancelConsentForFeatures:command];
        result(@"removeConsentstarRating!");  

    }else if ([@"setOptionalParametersForInitialization" isEqualToString:call.method]) {
        NSString* city = [command objectAtIndex:0];
        NSString* country = [command objectAtIndex:1];

        NSString* latitudeString = [command objectAtIndex:2];
        NSString* longitudeString = [command objectAtIndex:3];
        NSString* ipAddress = [command objectAtIndex:3];

        double latitudeDouble = [latitudeString doubleValue];
        double longitudeDouble = [longitudeString doubleValue];

        config.ISOCountryCode = country;
        config.city = city;
        config.location = (CLLocationCoordinate2D){latitudeDouble,longitudeDouble};
        config.IP = ipAddress;

        result(@"setOptionalParametersForInitialization!");

    }else if ([@"setRemoteConfigAutomaticDownload" isEqualToString:call.method]) {
        config.enableRemoteConfig = YES;
        config.remoteConfigCompletionHandler = ^(NSError * error)
        {
            if (!error){
                result(@"Success!");
            } else {
                result([@"Error :" stringByAppendingString: error.localizedDescription]);
            }
        };

    }else if ([@"remoteConfigUpdate" isEqualToString:call.method]) {
        [Countly.sharedInstance updateRemoteConfigWithCompletionHandler:^(NSError * error)
         {
             if (!error){
                 result(@"Success!");
             } else {
                 result([@"Error :" stringByAppendingString: error.localizedDescription]);
             }
         }];

    }else if ([@"updateRemoteConfigForKeysOnly" isEqualToString:call.method]) {
        NSArray * keysOnly[] = {};
        for(int i=0,il=(int)command.count;i<il;i++){
            keysOnly[i] = [command objectAtIndex:i];
        }
        [Countly.sharedInstance updateRemoteConfigOnlyForKeys: *keysOnly completionHandler:^(NSError * error)
         {
             if (!error){
                result(@"Success!");
             } else {
                 result([@"Error :" stringByAppendingString: error.localizedDescription]);
             }
         }];

    }else if ([@"updateRemoteConfigExceptKeys" isEqualToString:call.method]) {
        NSArray * exceptKeys[] = {};
        for(int i=0,il=(int)command.count;i<il;i++){
            exceptKeys[i] = [command objectAtIndex:i];
        }
        [Countly.sharedInstance updateRemoteConfigExceptForKeys: *exceptKeys completionHandler:^(NSError * error)
         {
             if (!error){
                 result(@"Success!");
             } else {
                 result([@"Error :" stringByAppendingString: error.localizedDescription]);
             }
         }];

    }else if ([@"remoteConfigClearValues" isEqualToString:call.method]) {
        [CountlyRemoteConfig.sharedInstance clearCachedRemoteConfig];
        result(@"Success!");

    }else if ([@"getRemoteConfigValueForKey" isEqualToString:call.method]) {
        id value = [Countly.sharedInstance remoteConfigValueForKey:[command objectAtIndex:0]];
        if(!value){
            value = @"Default Value";
        }
        result(value);

    }else if ([@"askForFeedback" isEqualToString:call.method]) {
        NSString* widgetId = [command objectAtIndex:0];
        NSString* URL = [Countly.sharedInstance getFeedbackWidget: widgetId];
        result(@"default!");

    }else if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

@end
