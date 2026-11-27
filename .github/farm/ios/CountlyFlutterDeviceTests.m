#import <XCTest/XCTest.h>
#import <Flutter/Flutter.h>
#import "CountlyFlutterPlugin.h"

extern NSString *const kCountlyFlutterSDKVersion;

/**
 * Drives the plugin's native iOS layer on a real iPhone the way Dart does: each call goes through
 * "handleMethodCall:result:" with the JSON arguments the Dart side sends. The server address does not
 * resolve, so every request stays in the queue, where the test reads it back.
 */
@interface CountlyFlutterDeviceTests : XCTestCase
@property(nonatomic) CountlyFlutterPlugin *plugin;
@end

@implementation CountlyFlutterDeviceTests

- (void)setUp {
    [super setUp];
    self.plugin = [[CountlyFlutterPlugin alloc] init];
}

/**
 * Sends one method call to the plugin and waits up to 10 seconds for its answer.
 * @param method the method name Dart uses
 * @param arguments the arguments Dart sends, encoded to the "data" JSON string
 * @return the plugin's answer
 */
- (id)call:(NSString *)method arguments:(NSArray *)arguments {
    NSData *json = [NSJSONSerialization dataWithJSONObject:arguments options:0 error:nil];
    NSString *data = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    FlutterMethodCall *call = [FlutterMethodCall methodCallWithMethodName:method arguments:@{@"data" : data}];
    XCTestExpectation *answered = [self expectationWithDescription:method];
    __block id answer = nil;
    [self.plugin handleMethodCall:call result:^(id result) {
      answer = result;
      [answered fulfill];
    }];
    [self waitForExpectations:@[ answered ] timeout:10];
    return answer;
}

- (void)testBridgeRecordsEventsAndViewsWithTheFlutterSDKName {
    NSString *deviceID = [@"flutter-farm-" stringByAppendingString:NSUUID.UUID.UUIDString];
    NSDictionary *config = @{
        @"serverURL" : @"https://countly.invalid",
        @"appKey" : @"flutter_farm_test",
        @"deviceID" : deviceID,
        @"loggingEnabled" : @YES,
        @"eventQueueSizeThreshold" : @1,
    };

    XCTAssertEqualObjects([self call:@"init" arguments:@[ config ]], @"initialized.");
    XCTAssertEqualObjects([self call:@"isInitialized" arguments:@[]], @"true");
    XCTAssertEqualObjects([self call:@"getID" arguments:@[]], deviceID);

    [self call:@"recordEvent" arguments:@[ @"farm_event", @"1", @"0", @"0", @{@"source" : @"farm"} ]];
    NSString *viewID = [self call:@"startView" arguments:@[ @"farm_view", @{} ]];
    XCTAssertGreaterThan(viewID.length, 0);

    NSArray<NSString *> *requests = [self call:@"getRequestQueue" arguments:@[]];
    NSString *all = [[requests componentsJoinedByString:@"\n"] stringByRemovingPercentEncoding];
    XCTAssertTrue([all containsString:@"farm_event"], @"%@", all);
    XCTAssertTrue([all containsString:@"sdk_name=dart-flutterb-ios"], @"%@", all);
    XCTAssertTrue([all containsString:[@"sdk_version=" stringByAppendingString:kCountlyFlutterSDKVersion]], @"%@", all);
    XCTAssertTrue([all containsString:deviceID], @"%@", all);

    [self call:@"halt" arguments:@[]];
}

@end
