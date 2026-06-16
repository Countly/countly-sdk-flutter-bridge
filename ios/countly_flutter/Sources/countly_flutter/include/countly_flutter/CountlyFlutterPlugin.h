#import <Flutter/Flutter.h>

@interface CountlyFlutterPlugin : NSObject <FlutterPlugin>
+ (void)startObservingNotifications;
+ (void)onNotification:(NSDictionary *)notificationMessage; // :(Boolean *)isInline :(Boolean *)coldstart
- (void)recordPushAction;
@end
