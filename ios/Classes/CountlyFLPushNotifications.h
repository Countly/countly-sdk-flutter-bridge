// CountlyFLPushNotifications.h
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface CountlyFLPushNotifications : NSObject
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
@property (nonatomic, assign) BOOL enablePushNotifications;

+ (instancetype _Nonnull )sharedInstance;

- (void)recordPushActions;
- (void)disablePushNotifications;
- (void)stopObservingNotifications;
- (void)startObservingNotifications;
- (void)askForNotificationPermission;
- (void)onNotification:(NSDictionary *_Nullable)notification;
- (void) registerForNotification:(FlutterResult _Nonnull ) result;
- (void)onNotificationResponse:(UNNotificationResponse* _Nullable)response;
#endif
@end
