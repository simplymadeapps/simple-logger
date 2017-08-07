//
//  ViewControllerTests.m
//  SimpleLogger
//
//  Created by Bill Burgess on 8/7/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"

@interface ViewControllerTests : SLTestCase

@end

@implementation ViewControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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
}

@end
