// CountlyFLPushNotifications.m
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#import "CountlyFLPushNotifications.h"
#import "UserNotifications/UserNotifications.h"
#import "CountlyCommon.h"

#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
NSDictionary *lastStoredNotification = nil;
FlutterResult notificationListener = nil;
NSMutableArray *notifications = nil;

typedef NSString* CLYUserDefaultKey NS_EXTENSIBLE_STRING_ENUM;
CLYUserDefaultKey const CLYPushNotificationsKey  = @"notificationsKey";
CLYUserDefaultKey const CLYPushButtonIndexKey = @"notificationBtnIndexKey";
#endif
@interface CountlyFLPushNotifications () <UNUserNotificationCenterDelegate>
@end

@implementation CountlyFLPushNotifications
#ifndef COUNTLY_EXCLUDE_PUSHNOTIFICATIONS
+ (instancetype)sharedInstance
{
	static CountlyFLPushNotifications* s_sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{s_sharedInstance = self.new;});
	s_sharedInstance.enablePushNotifications = true;
	return s_sharedInstance;
}

- (instancetype)init
{
	if (self = [super init])
	{
		
	}
	
	notifications = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:CLYPushNotificationsKey];
	return self;
}

- (void) disablePushNotifications {
	dispatch_async(dispatch_get_main_queue(), ^ {
		self->_enablePushNotifications = false;
	});
}

- (void)stopObservingNotifications
{
	if (UNUserNotificationCenter.currentNotificationCenter.delegate == self)
		UNUserNotificationCenter.currentNotificationCenter.delegate = nil;
}

- (void)startObservingNotifications {
	UNUserNotificationCenter.currentNotificationCenter.delegate = self;
}

- (void) askForNotificationPermission {
	dispatch_async(dispatch_get_main_queue(), ^ {
		[Countly.sharedInstance askForNotificationPermission];
	});
}

- (void) saveListener:(FlutterResult) result{
	notificationListener = result;
}

- (void) registerForNotification:(FlutterResult) result{
	dispatch_async(dispatch_get_main_queue(), ^ {
		notificationListener = result;
		if(lastStoredNotification != nil){
			result([lastStoredNotification description]);
			lastStoredNotification = nil;
		}
	});
	
}

- (void) recordPushActions {
	NSMutableArray* _notifications = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:CLYPushNotificationsKey];
	if(_notifications != nil) {
		for (NSMutableDictionary *notificationMessage in _notifications) {
			[self recordPushAction:notificationMessage];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:CLYPushNotificationsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) recordPushAction:(NSMutableDictionary *)notificationMessage {
	if (notificationMessage != nil)
	{
		NSNumber *buttonIndex = notificationMessage[CLYPushButtonIndexKey];
		NSInteger responseBtnIndex = buttonIndex.intValue;
		NSMutableDictionary* responseDictionary =  [notificationMessage mutableCopy];
		[responseDictionary removeObjectForKey:CLYPushButtonIndexKey];
		
		if([responseDictionary count] > 0) {
			
			NSDictionary* countlyPayload = responseDictionary[kCountlyPNKeyCountlyPayload];
			NSString* URL = @"";
			if (responseBtnIndex == 0)
			{
				URL = countlyPayload[kCountlyPNKeyDefaultURL];
			}
			else
			{
				URL = countlyPayload[kCountlyPNKeyButtons][responseBtnIndex - 1][kCountlyPNKeyActionButtonURL];
			}
			
			[Countly.sharedInstance recordActionForNotification:responseDictionary clickedButtonIndex:responseBtnIndex];
			
			[self openURL:URL];
		}
		
	}
}

- (void)openURL:(NSString *)URLString
{
	if (!URLString)
		return;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[UIApplication.sharedApplication openURL:[NSURL URLWithString:URLString] options:@{} completionHandler:nil];
		
	});
}

// when user open the app by tapping notification in any state.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler{
	[self onNotificationResponse: response];
	
	id<UNUserNotificationCenterDelegate> appDelegate = (id<UNUserNotificationCenterDelegate>)UIApplication.sharedApplication.delegate;
	if ([appDelegate respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
		[appDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
	else
		completionHandler();
}

// When app is running and notification received
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
	[self onNotification: notification.request.content.userInfo];
	NSDictionary* countlyPayload = notification.request.content.userInfo[kCountlyPNKeyCountlyPayload];
	NSString* notificationID = countlyPayload[kCountlyPNKeyNotificationID];
	
	if (notificationID)
	{
		UNNotificationPresentationOptions presentationOption = UNNotificationPresentationOptionNone;
		if (@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *))
		{
			presentationOption = UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner;
		}
		else
		{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
			presentationOption = UNNotificationPresentationOptionAlert;
#pragma GCC diagnostic pop
		}
		completionHandler(presentationOption);
	}
	
	id<UNUserNotificationCenterDelegate> appDelegate = (id<UNUserNotificationCenterDelegate>)UIApplication.sharedApplication.delegate;
	
	if ([appDelegate respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)])
		[appDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
	else
		completionHandler(UNNotificationPresentationOptionNone);
}

- (void)onNotification:(NSDictionary *)notificationMessage
{
	NSLog(@"The notification %@", [CountlyFLPushNotifications toJSON:notificationMessage]);
	if(notificationMessage && notificationListener != nil){
		lastStoredNotification = notificationMessage;
		notificationListener(@[[CountlyFLPushNotifications toJSON:notificationMessage]]);
	}else{
		lastStoredNotification = notificationMessage;
	}
}

- (void)onNotificationResponse:(UNNotificationResponse *)response
API_AVAILABLE(ios(10.0)){
	NSDictionary* notificationDictionary = response.notification.request.content.userInfo;
	NSInteger buttonIndex = 0;
	if ([response.actionIdentifier hasPrefix:kCountlyActionIdentifier])
	{
		buttonIndex = [[response.actionIdentifier stringByReplacingOccurrencesOfString:kCountlyActionIdentifier withString:@""] integerValue];
	}
	if(!CountlyCommon.sharedInstance.hasStarted) {
		if(notifications == nil){
			notifications = [[NSMutableArray alloc] init];
		}
		NSMutableDictionary *mutableNotification = [notificationDictionary mutableCopy];
		mutableNotification[CLYPushButtonIndexKey] = [NSNumber numberWithInteger:buttonIndex];
		[notifications insertObject:mutableNotification atIndex:[notifications count]];
		[[NSUserDefaults standardUserDefaults] setObject:notifications forKey:CLYPushNotificationsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	[self onNotification:notificationDictionary];
}

+ (NSString *) toJSON: (NSDictionary  *) json{
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
	
	if (! jsonData) {
		NSLog(@"Got an error: %@", error);
		return [NSString stringWithFormat:@"{'error': '%@'}", error];
	} else {
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		return jsonString;
	}
}
#endif

@end
