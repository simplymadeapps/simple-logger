//
//  ViewControllerTests.m
//  SimpleLogger
//
//  Created by Bill Burgess on 8/7/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "SimpleLogger.h"

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
	[tester tapViewWithAccessibilityLabel:@"Add"];
	
	[tester waitForViewWithAccessibilityLabel:@"Add Log"];
	
	[tester enterTextIntoCurrentFirstResponder:@"Adding Test Log"];
	
	[tester tapViewWithAccessibilityLabel:@"Add Log" traits:UIAccessibilityTraitButton];
	
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	NSDate *date = [NSDate date];
	NSString *filename = [logger filenameForDate:date];
	
	[tester waitForViewWithAccessibilityLabel:filename];
}

- (void)testLogDetailViewIsPresented {
	[tester tapViewWithAccessibilityLabel:@"Add"];
	
	[tester waitForViewWithAccessibilityLabel:@"Add Log"];
	
	[tester enterTextIntoCurrentFirstResponder:@"Adding Test Log"];
	
	[tester tapViewWithAccessibilityLabel:@"Add Log" traits:UIAccessibilityTraitButton];
	
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	NSDate *date = [NSDate date];
	NSString *filename = [logger filenameForDate:date];
	
	[tester waitForViewWithAccessibilityLabel:filename];
	[tester tapViewWithAccessibilityLabel:filename];
	
	[tester waitForViewWithAccessibilityLabel:@"Log"];
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testLogDetailViewUploadIsCalled {
	//AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
	//[[transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id _Nullable(AWSTask * _Nonnull task) {
		//block(task);
		//return nil;
	//}];
	[SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
	
	AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];

	id mock = OCMPartialMock(transferManager);
	[[[mock expect] upload:[OCMArg any]] continueWithExecutor:[OCMArg any] withBlock:[OCMArg any]];

	[tester tapViewWithAccessibilityLabel:@"Add"];
	
	[tester waitForViewWithAccessibilityLabel:@"Add Log"];
	
	[tester enterTextIntoCurrentFirstResponder:@"Adding Test Log"];
	
	[tester tapViewWithAccessibilityLabel:@"Add Log" traits:UIAccessibilityTraitButton];
	
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	NSDate *date = [NSDate date];
	NSString *filename = [logger filenameForDate:date];
	
	[tester waitForViewWithAccessibilityLabel:filename];
	[tester tapViewWithAccessibilityLabel:filename];
	
	[tester waitForViewWithAccessibilityLabel:@"Upload"];
	[tester tapViewWithAccessibilityLabel:@"Upload"];
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
	
	[mock verify];
	[mock stopMocking];
	mock = nil;
}

@end
