//
//  AutomaticEventsTests.m
//  HelloMixpanel
//
//  Created by Yarden Eitan on 4/25/17.
//  Copyright © 2017 Mixpanel. All rights reserved.
//

#import "MixpanelBaseTests.h"
#import "AutomaticEvents.h"
#import "MixpanelPrivate.h"
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface AutomaticEventsTests : MixpanelBaseTests

//@property (nonatomic, strong) AutomaticEvents *automaticEvents;

@end

@implementation AutomaticEventsTests {
    NSTimeInterval startTime;
}


- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *firstOpenKey = @"MPFirstOpen";
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"Mixpanel"];
    [defaults setObject:nil forKey:firstOpenKey];
    [defaults synchronize];
    NSString *searchPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    [NSFileManager.defaultManager removeItemAtPath:searchPath error:nil];
    [super setUp];
    startTime = [[NSDate date] timeIntervalSince1970];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFirstOpen {
    [self waitForMixpanelQueues];
    XCTAssert(self.mixpanel.eventsQueue.count == 1, @"First App Open Should be tracked");
}

- (void)testSession {
    [self.mixpanel.automaticEvents performSelector:NSSelectorFromString(@"appWillResignActive:") withObject:nil];
    [self waitForMixpanelQueues];
    NSDictionary *event = [self.mixpanel.eventsQueue lastObject];
    XCTAssertNotNil(event, @"should have an event");
    XCTAssert([event[@"event"] isEqualToString:@"$ae_session"], @"should be app session event");
    XCTAssertNotNil(event[@"properties"][@"$ae_session_length"], @"should have session length");
}

- (void)testUpdated {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"Mixpanel"];
    NSDictionary* infoDict = [NSBundle mainBundle].infoDictionary;
    NSString* appVersionValue = infoDict[@"CFBundleShortVersionString"];
    NSString* savedVersionValue = [defaults stringForKey:@"MPAppVersion"];
    XCTAssert(appVersionValue == savedVersionValue, @"saved version and current version need to be the same");
}

- (void)testMultipleInstances {
    Mixpanel *mp = [[Mixpanel alloc] initWithToken:@"abc"
                                      launchOptions:nil
                                   andFlushInterval:60];
    mp.automaticEventsEnabled = @FALSE;
    self.mixpanel.automaticEventsEnabled = @TRUE;
    [self.mixpanel.automaticEvents performSelector:NSSelectorFromString(@"appWillResignActive:") withObject:nil];
    [self waitForMixpanelQueues];
    dispatch_sync(mp.serialQueue, ^{
        dispatch_sync(mp.networkQueue, ^{ return; });
    });
    NSDictionary *event = [self.mixpanel.eventsQueue lastObject];
    XCTAssertNotNil(event, @"should have an event");
    XCTAssert([event[@"event"] isEqualToString:@"$ae_session"], @"should be app session event");
    XCTAssertNotNil(event[@"properties"][@"$ae_session_length"], @"should have session length");
    NSDictionary *otherEvent = [mp.eventsQueue lastObject];
    XCTAssertNil(otherEvent, @"shouldn't have an event");
}

@end