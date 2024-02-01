// CountlyConfig.m
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#import "CountlyCommon.h"

@interface CountlyConfig ()
@property (nonatomic) NSMutableArray<RCDownloadCallback> *remoteConfigGlobalCallbacks;
@end

@interface CountlyAPMConfig ()
- (void)enableAPMInternal:(BOOL)enableAPM;
@end

@implementation CountlyConfig

//NOTE: Countly features
#if (TARGET_OS_IOS)
CLYFeature const CLYPushNotifications   = @"CLYPushNotifications";
CLYFeature const CLYCrashReporting      = @"CLYCrashReporting";
// CLYAutoViewTracking is deprecated, Use 'config.enableAutomaticViewTracking' instead
CLYFeature const CLYAutoViewTracking    = @"CLYAutoViewTracking" ;
#elif (TARGET_OS_WATCH)
CLYFeature const CLYCrashReporting      = @"CLYCrashReporting";
#elif (TARGET_OS_TV)
CLYFeature const CLYCrashReporting      = @"CLYCrashReporting";
// CLYAutoViewTracking is deprecated, Use 'config.enableAutomaticViewTracking' instead
CLYFeature const CLYAutoViewTracking    = @"CLYAutoViewTracking";
#elif (TARGET_OS_OSX)
CLYFeature const CLYPushNotifications   = @"CLYPushNotifications";
CLYFeature const CLYCrashReporting      = @"CLYCrashReporting";
#endif

CountlyAPMConfig *apmConfig = nil;

//NOTE: Device ID options
NSString* const CLYDefaultDeviceID = @""; //NOTE: It will be overridden to default device ID mechanism, depending on platform.
NSString* const CLYTemporaryDeviceID = @"CLYTemporaryDeviceID";

//NOTE: Device ID Types
CLYDeviceIDType const CLYDeviceIDTypeCustom     = @"CLYDeviceIDTypeCustom";
CLYDeviceIDType const CLYDeviceIDTypeTemporary  = @"CLYDeviceIDTypeTemporary";
CLYDeviceIDType const CLYDeviceIDTypeIDFV       = @"CLYDeviceIDTypeIDFV";
CLYDeviceIDType const CLYDeviceIDTypeNSUUID     = @"CLYDeviceIDTypeNSUUID";

- (instancetype)init
{
    if (self = [super init])
    {
#if (TARGET_OS_WATCH)
        self.updateSessionPeriod = 20.0;
#else
        self.updateSessionPeriod = 60.0;
#endif
        self.eventSendThreshold = 100;
        self.storedRequestsLimit = 1000;
        self.crashLogLimit = 100;
        
        self.maxKeyLength = 128;
        self.maxValueLength = 256;
        self.maxSegmentationValues = 100;
        
        self.location = kCLLocationCoordinate2DInvalid;
        
        self.URLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration;
        
        self.internalLogLevel = CLYInternalLogLevelDebug;
        
        self.enableOrientationTracking = YES;
        self.enableServerConfiguration = NO;
        self.remoteConfigGlobalCallbacks = NSMutableArray.new;
    }
    
    return self;
}

-(void)remoteConfigRegisterGlobalCallback:(RCDownloadCallback) callback
{
    [self.remoteConfigGlobalCallbacks addObject:callback];
    
}


- (NSMutableArray<RCDownloadCallback> *) getRemoteConfigGlobalCallbacks
{
    return self.remoteConfigGlobalCallbacks;
}

- (void)setEnablePerformanceMonitoring:(BOOL)enablePerformanceMonitoring
{
    if (apmConfig == nil) {
        apmConfig = CountlyAPMConfig.new;
    }
    [apmConfig enableAPMInternal:enablePerformanceMonitoring];
    
}

- (nonnull CountlyAPMConfig *)apm {
    if (apmConfig == nil) {
        apmConfig = CountlyAPMConfig.new;
    }
    return apmConfig;
}

@end
