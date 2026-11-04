// CountlyFLPushNotifications.m
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#import "CountlyFLPushNotifications.h"
#import "CountlyCommon.h"
#import "CountlyPushNotifications.h"
#import "UserNotifications/UserNotifications.h"

#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
NSUInteger const kCountlyFLMaxPendingNotifications = 50;
NSMutableArray<NSString *> *pendingNotifications = nil;
FlutterResult notificationListener = nil;
NSMutableArray *notifications = nil;
// Clicked notifications no "onNotificationOpened" request waited for yet, oldest first.
static NSMutableArray<NSDictionary *> *pendingOpenedNotifications = nil;
static FlutterResult notificationOpenedListener = nil;
// The channel of the engine whose Dart made the waiting "onNotificationOpened" request.
static id notificationOpenedListenerOwner = nil;
// Set while a notification is passed on to the app delegate, whose calls back into this class are then skipped.
static BOOL isForwardingToAppDelegate = NO;

typedef NSString *CLYUserDefaultKey NS_EXTENSIBLE_STRING_ENUM;
CLYUserDefaultKey const CLYPushNotificationsKey = @"notificationsKey";
CLYUserDefaultKey const CLYPushButtonIndexKey = @"notificationBtnIndexKey";
#endif
@interface CountlyFLPushNotifications () <UNUserNotificationCenterDelegate>
@end

@implementation CountlyFLPushNotifications
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
+ (instancetype)sharedInstance {
    static CountlyFLPushNotifications *s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      s_sharedInstance = self.new;
      s_sharedInstance.enablePushNotifications = true;
    });
    return s_sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
    }

    notifications = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:CLYPushNotificationsKey];
    return self;
}

- (void)disablePushNotifications {
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_enablePushNotifications = false;
    });
}

- (void)stopObservingNotifications {
    if (UNUserNotificationCenter.currentNotificationCenter.delegate == self)
        UNUserNotificationCenter.currentNotificationCenter.delegate = nil;
}

- (void)startObservingNotifications {
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
}

- (void)askForNotificationPermission {
    dispatch_async(dispatch_get_main_queue(), ^{
      [Countly.sharedInstance askForNotificationPermission];
    });
}

/**
 * Hands the next push notification to a one-shot listener that answers a single Dart request. A
 * notification that arrived while no listener was waiting is delivered right away.
 */
- (void)registerForNotification:(FlutterResult)result {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (pendingNotifications.count > 0) {
          NSString *pendingNotification = pendingNotifications.firstObject;
          [pendingNotifications removeObjectAtIndex:0];
          result(pendingNotification);
          return;
      }
      notificationListener = result;
    });
}

/**
 * Hands the next clicked push notification to a one-shot listener that answers a single Dart
 * request. A click made while no listener was waiting is delivered right away; a newer request
 * replaces the waiting one.
 */
- (void)registerForNotificationOpened:(FlutterResult)result owner:(id)owner {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (pendingOpenedNotifications.count > 0) {
          NSDictionary *pendingOpened = pendingOpenedNotifications.firstObject;
          [pendingOpenedNotifications removeObjectAtIndex:0];
          result(pendingOpened);
          return;
      }
      notificationOpenedListener = result;
      notificationOpenedListenerOwner = owner;
    });
}

/**
 * Drops the waiting "onNotificationOpened" request of an engine that goes away, so that the next
 * click waits for the next engine's request instead of being answered to a dead one.
 */
- (void)stopNotificationOpenedRequestOf:(id)owner {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (notificationOpenedListenerOwner == owner) {
          notificationOpenedListener = nil;
          notificationOpenedListenerOwner = nil;
      }
    });
}

- (void)recordPushActions {
    NSMutableArray *_notifications = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:CLYPushNotificationsKey];
    if (_notifications != nil) {
        for (NSMutableDictionary *notificationMessage in _notifications) {
            [self recordPushAction:notificationMessage];
        }
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CLYPushNotificationsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)recordPushAction:(NSMutableDictionary *)notificationMessage {
    if (notificationMessage != nil) {
        NSNumber *buttonIndex = notificationMessage[CLYPushButtonIndexKey];
        NSInteger responseBtnIndex = buttonIndex.intValue;
        NSMutableDictionary *responseDictionary = [notificationMessage mutableCopy];
        [responseDictionary removeObjectForKey:CLYPushButtonIndexKey];

        if ([responseDictionary count] > 0) {

            NSDictionary *countlyPayload = responseDictionary[kCountlyPNKeyCountlyPayload];
            NSString *URL = @"";
            if (responseBtnIndex == 0) {
                URL = countlyPayload[kCountlyPNKeyDefaultURL];
            } else {
                URL = countlyPayload[kCountlyPNKeyButtons][responseBtnIndex - 1][kCountlyPNKeyActionButtonURL];
            }

            [Countly.sharedInstance recordActionForNotification:responseDictionary clickedButtonIndex:responseBtnIndex];

            [self openURL:URL];
        }
    }
}

- (void)openURL:(NSString *)URLString {
    if (!URLString)
        return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [UIApplication.sharedApplication openURL:[NSURL URLWithString:URLString] options:@{} completionHandler:nil];
    });
}

// when user open the app by tapping notification in any state.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [self onNotificationResponse:response];

    id<UNUserNotificationCenterDelegate> appDelegate = (id<UNUserNotificationCenterDelegate>)UIApplication.sharedApplication.delegate;
    if ([appDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        [self forwardToAppDelegate:^{
          [appDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        }];
    } else {
        completionHandler();
    }
}

// When app is running and notification received
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    [self onNotification:notification.request.content.userInfo];
    NSDictionary *countlyPayload = notification.request.content.userInfo[kCountlyPNKeyCountlyPayload];
    NSString *notificationID = countlyPayload[kCountlyPNKeyNotificationID];

    if (notificationID && !CountlyPushNotifications.sharedInstance.doNotShowAlertForNotifications) {
        UNNotificationPresentationOptions presentationOption = UNNotificationPresentationOptionNone;
        if (@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)) {
            presentationOption = UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner;
        } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            presentationOption = UNNotificationPresentationOptionAlert;
#pragma GCC diagnostic pop
        }
        completionHandler(presentationOption);
    }

    id<UNUserNotificationCenterDelegate> appDelegate = (id<UNUserNotificationCenterDelegate>)UIApplication.sharedApplication.delegate;

    if ([appDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
        [self forwardToAppDelegate:^{
          [appDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
        }];
    } else {
        completionHandler(UNNotificationPresentationOptionNone);
    }
}

/**
 * Runs the block that passes a notification on to the app delegate. Calls the app delegate makes back
 * into this class from inside it are skipped, because the notification was handled already.
 */
- (void)forwardToAppDelegate:(void (^)(void))forward {
    isForwardingToAppDelegate = YES;
    forward();
    isForwardingToAppDelegate = NO;
}

/**
 * Hands a push notification to "onNotification" as JSON text.
 */
- (void)onNotification:(NSDictionary *)notificationMessage {
    if (!notificationMessage || isForwardingToAppDelegate) {
        return;
    }
    [self deliverNotification:[CountlyFLPushNotifications toJSON:notificationMessage]];
}

/**
 * Delivers a push notification as JSON text to the waiting listener, or queues it until Dart asks
 * for the next one. The listener is consumed, so a Dart request is never answered twice; the queue
 * keeps the newest kCountlyFLMaxPendingNotifications notifications.
 */
- (void)deliverNotification:(NSString *)notificationJSON {
    CLY_LOG_D(@"%s, notification received: %@", __FUNCTION__, notificationJSON);
    dispatch_async(dispatch_get_main_queue(), ^{
      FlutterResult listener = notificationListener;
      notificationListener = nil;
      if (listener != nil) {
          listener(notificationJSON);
          return;
      }
      if (pendingNotifications == nil) {
          pendingNotifications = [NSMutableArray array];
      }
      if (pendingNotifications.count >= kCountlyFLMaxPendingNotifications) {
          [pendingNotifications removeObjectAtIndex:0];
      }
      [pendingNotifications addObject:notificationJSON];
    });
}

/**
 * Hands a response to a notification to "onNotification", and a click to "onNotificationOpened".
 */
- (void)onNotificationResponse:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0)) {
    if (isForwardingToAppDelegate) {
        return;
    }
    [self onNotificationResponse:response.notification.request.content.userInfo actionIdentifier:response.actionIdentifier];
}

/**
 * Keeps the response to a notification for "recordPushActions" when the SDK has not started yet and
 * hands the notification to "onNotification". A click on a Countly notification or on one of its
 * buttons also goes to "onNotificationOpened" with the index of the clicked action; a dismissal or
 * another app's action does not.
 */
- (void)onNotificationResponse:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier {
    if (!notificationDictionary) {
        return;
    }
    NSInteger buttonIndex = 0;
    if ([actionIdentifier hasPrefix:kCountlyActionIdentifier]) {
        buttonIndex = [[actionIdentifier stringByReplacingOccurrencesOfString:kCountlyActionIdentifier withString:@""] integerValue];
    }
    if (!CountlyCommon.sharedInstance.hasStarted) {
        if (notifications == nil) {
            notifications = [[NSMutableArray alloc] init];
        }
        NSMutableDictionary *mutableNotification = [notificationDictionary mutableCopy];
        mutableNotification[CLYPushButtonIndexKey] = [NSNumber numberWithInteger:buttonIndex];
        [notifications insertObject:mutableNotification atIndex:[notifications count]];
        [[NSUserDefaults standardUserDefaults] setObject:notifications forKey:CLYPushNotificationsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    NSString *notificationJSON = [CountlyFLPushNotifications toJSON:notificationDictionary];
    [self deliverNotification:notificationJSON];
    BOOL clicked = buttonIndex > 0 || [actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier];
    if (clicked && notificationDictionary[kCountlyPNKeyCountlyPayload][kCountlyPNKeyNotificationID]) {
        [self deliverNotificationOpened:notificationJSON actionIndex:buttonIndex];
    }
}

/**
 * Delivers a clicked push notification, as the JSON text "onNotification" got, and the index of the
 * clicked action to the waiting listener, or queues it until Dart asks. The listener is consumed, so a
 * Dart request is never answered twice; the queue keeps the newest kCountlyFLMaxPendingNotifications.
 */
- (void)deliverNotificationOpened:(NSString *)notificationJSON actionIndex:(NSInteger)actionIndex {
    NSDictionary *opened = @{@"notification" : notificationJSON, @"actionIndex" : @(actionIndex)};
    dispatch_async(dispatch_get_main_queue(), ^{
      FlutterResult listener = notificationOpenedListener;
      notificationOpenedListener = nil;
      notificationOpenedListenerOwner = nil;
      if (listener != nil) {
          listener(opened);
          return;
      }
      if (pendingOpenedNotifications == nil) {
          pendingOpenedNotifications = [NSMutableArray array];
      }
      if (pendingOpenedNotifications.count >= kCountlyFLMaxPendingNotifications) {
          [pendingOpenedNotifications removeObjectAtIndex:0];
      }
      [pendingOpenedNotifications addObject:opened];
    });
}

+ (NSString *)toJSON:(NSDictionary *)json {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];

    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return [NSString stringWithFormat:@"{'error': '%@'}", error];
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
}
#endif

@end
