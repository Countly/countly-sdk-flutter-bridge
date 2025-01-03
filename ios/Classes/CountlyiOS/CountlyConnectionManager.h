// CountlyConnectionManager.h
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#import <Foundation/Foundation.h>
#import "Resettable.h"

extern NSString* const kCountlyQSKeyAppKey;
extern NSString* const kCountlyQSKeyDeviceID;
extern NSString* const kCountlyQSKeyDeviceIDType;
extern NSString* const kCountlyQSKeySDKVersion;
extern NSString* const kCountlyQSKeySDKName;
extern NSString* const kCountlyQSKeyMethod;
extern NSString* const kCountlyQSKeyMetrics;

extern NSString* const kCountlyEndpointI;
extern NSString* const kCountlyEndpointO;
extern NSString* const kCountlyEndpointSDK;
extern NSString* const kCountlyEndpointFeedback;
extern NSString* const kCountlyEndpointWidget;
extern NSString* const kCountlyEndpointSurveys;
extern NSString* const kCountlyRCKeyKeys;
extern NSString* const kCountlyQSKeyTimestamp;

extern const NSInteger kCountlyGETRequestMaxLength;

@interface CountlyConnectionManager : NSObject <NSURLSessionDelegate, Resettable>

@property (nonatomic) NSString* appKey;
@property (nonatomic) NSString* host;
@property (nonatomic) NSURLSessionTask* connection;
@property (nonatomic) NSArray* pinnedCertificates;
@property (nonatomic) NSString* secretSalt;
@property (nonatomic) BOOL alwaysUsePOST;
@property (nonatomic) NSURLSessionConfiguration* URLSessionConfiguration;

@property (nonatomic) BOOL isTerminating;

+ (instancetype)sharedInstance;

- (void)beginSession;
- (void)updateSession;
- (void)endSession;

- (void)sendEventsWithSaveIfNeeded;
- (void)sendEvents;
- (void)attemptToSendStoredRequests;
- (void)sendPushToken:(NSString *)token;
- (void)sendLocationInfo;
- (void)sendUserDetails:(NSString *)userDetails;
- (void)sendCrashReport:(NSString *)report immediately:(BOOL)immediately;
- (void)sendOldDeviceID:(NSString *)oldDeviceID;
- (void)sendAttribution;
- (void)sendDirectAttributionWithCampaignID:(NSString *)campaignID andCampaignUserID:(NSString *)campaignUserID;
- (void)sendAttributionData:(NSString *)attributionData;
- (void)sendIndirectAttribution:(NSDictionary *)attribution;
- (void)sendConsents:(NSString *)consents;
- (void)sendPerformanceMonitoringTrace:(NSString *)trace;

- (void)sendEnrollABRequestForKeys:(NSArray*)keys;
- (void)sendExitABRequestForKeys:(NSArray*)keys;

- (void)addDirectRequest:(NSDictionary<NSString *, NSString *> *)requestParameters;

- (void)proceedOnQueue;

- (NSString *)queryEssentials;
- (NSString *)appendChecksum:(NSString *)queryString;

- (BOOL)isSessionStarted;

@end
