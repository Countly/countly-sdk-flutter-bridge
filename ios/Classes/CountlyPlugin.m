#import "CountlyPlugin.h"
#import "Countly.h"
#import "CountlyConfig.h"

CountlyConfig* config = nil;

@implementation CountlyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"countly"
            binaryMessenger:[registrar messenger]];
  CountlyPlugin* instance = [[CountlyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"init" isEqualToString:call.method]){

        NSString* commandString = call.arguments[@"data"];
        NSData* data = [commandString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *e;
        NSArray *command = [NSJSONSerialization JSONObjectWithData:data options:nil error:&e];

        NSString* serverurl = [command  objectAtIndex:0];
        NSString* appkey = [command objectAtIndex:1];
        NSString* deviceID = @"";

        if(config == nil){
            config = CountlyConfig.new;
        }
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
  }else if ([@"getPlatformVersion" isEqualToString:call.method]) {
                result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }
  else {
    result(FlutterMethodNotImplemented);
  }

//    if ([@"getPlatformVersion" isEqualToString:call.method]) {
//        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
//    } else {
//        result(FlutterMethodNotImplemented);
//    }

}

@end
