//
//  ViewControllerTests.m
//  SimpleLogger
//
//  Created by Bill Burgess on 8/7/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "SimpleLogger.h"
#import "FileManager.h"
#import <AWSS3/AWSS3.h>

@interface ViewControllerTests : SLTestCase

@end

@implementation ViewControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [SimpleLogger removeAllLogFiles];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [SimpleLogger removeAllLogFiles];
    [self deleteRegularFiles];
    
    [super tearDown];
}

- (void)testAddLogButtonIsPresentedAndAddsLog {
    [self saveRegularFiles:2];
    
    [tester tapViewWithAccessibilityLabel:@"Add"];
    
    [tester waitForViewWithAccessibilityLabel:@"Add Log"];
    
    [tester enterTextIntoCurrentFirstResponder:@"Adding Test Log"];
    
    [tester tapViewWithAccessibilityLabel:@"Add Log" traits:UIAccessibilityTraitButton];
    
    NSDate *date = [NSDate date];
    NSString *filename = [FileManager filenameForDate:date];
    
    [tester waitForViewWithAccessibilityLabel:filename];
}

- (void)testLogDetailViewIsPresented {
    [tester tapViewWithAccessibilityLabel:@"Add"];
    
    [tester waitForViewWithAccessibilityLabel:@"Add Log"];
    
    [tester enterTextIntoCurrentFirstResponder:@"Adding Test Log"];
    
    [tester tapViewWithAccessibilityLabel:@"Add Log" traits:UIAccessibilityTraitButton];
    
    NSDate *date = [NSDate date];
    NSString *filename = [FileManager filenameForDate:date];
    
    [tester waitForViewWithAccessibilityLabel:filename];
    [tester tapViewWithAccessibilityLabel:filename];
    
    [tester waitForViewWithAccessibilityLabel:@"Log"];
    
    [tester tapViewWithAccessibilityLabel:@"Simple Logger"];
}

- (void)testLogDetailViewUploadIsCalled {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    
    AWSTask *task = [[AWSTask alloc] init];
    id taskMock = OCMPartialMock(task);
    id transferMock = OCMPartialMock(transferUtility);
    [[[transferMock stub] andReturn:taskMock] uploadFile:[OCMArg any] bucket:[OCMArg any] key:[OCMArg any] contentType:[OCMArg any] expression:nil completionHandler:[OCMArg invokeBlockWithArgs:taskMock, [NSNull null], nil]];
    
    [tester tapViewWithAccessibilityLabel:@"Add"];
    
    [tester waitForViewWithAccessibilityLabel:@"Add Log"];
    
    [tester enterTextIntoCurrentFirstResponder:@"Adding Test Log"];
    
    [tester tapViewWithAccessibilityLabel:@"Add Log" traits:UIAccessibilityTraitButton];
    
    NSDate *date = [NSDate date];
    NSString *filename = [FileManager filenameForDate:date];
    
    [tester waitForViewWithAccessibilityLabel:filename];
    [tester tapViewWithAccessibilityLabel:filename];
    
    [tester waitForViewWithAccessibilityLabel:@"Upload"];
    [tester tapViewWithAccessibilityLabel:@"Upload"];
    
    [tester tapViewWithAccessibilityLabel:@"Simple Logger"];
    
    [taskMock verify];
    [taskMock stopMocking];
    taskMock = nil;
    
    [transferMock verify];
    [transferMock stopMocking];
    transferMock = nil;
}

@end
