//
//  NSDate+SIOTests.m
//  SIOAPIExample
//
//  Created by Bill Burgess on 5/12/17.
//  Copyright © 2017 Simply Made Apps. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDate+SMA.h"

@interface NSDate_SMATests : XCTestCase
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation NSDate_SMATests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateFormat = @"MM-dd-yyyy";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	
	self.dateFormatter = nil;
	
    [super tearDown];
}

- (void)testDateByAddingDaysWorksCorrectly {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateByAddingDays:1];
	NSString *value = [self.dateFormatter stringFromDate:newDate];
	
	XCTAssertEqualObjects(value, @"01-10-1979");
}

- (void)testDateBySubtractingDaysWorksCorrectly {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateBySubtractingDays:1];
	NSString *value = [self.dateFormatter stringFromDate:newDate];
	
	XCTAssertEqualObjects(value, @"01-08-1979");
}

- (void)testIsLaterThanDateReturnsTrue {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateBySubtractingDays:1];
	
	XCTAssertTrue([date isLaterThanDate:newDate]);
}

- (void)testIsLaterThanDateReturnsFalse {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateByAddingDays:1];
	
	XCTAssertFalse([date isLaterThanDate:newDate]);
}

- (void)testIsLaterThanDateReturnsFalseWhenEqual {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateBySubtractingDays:0];
	
	XCTAssertFalse([date isLaterThanDate:newDate]);
}

- (void)testIsEarlierThanDateReturnsTrue {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateByAddingDays:1];
	
	XCTAssertTrue([date isEarlierThanDate:newDate]);
}

- (void)testIsEarlierThanDateReturnsFalse {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateBySubtractingDays:1];
	
	XCTAssertFalse([date isEarlierThanDate:newDate]);
}

- (void)testIsEarlierThanDateReturnsFalseWhenEqual {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *newDate = [date dateByAddingDays:0];
	
	XCTAssertFalse([date isEarlierThanDate:newDate]);
}

- (void)testIsBetweenDateReturnsTrue {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *startDate = [date dateBySubtractingDays:1];
	NSDate *endDate = [date dateByAddingDays:1];
	
	XCTAssertTrue([date isBetweenDate:startDate andDate:endDate]);
}

- (void)testIsBetweenDateReturnsFalse {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *startDate = [date dateByAddingDays:1];
	NSDate *endDate = [date dateByAddingDays:2];
	
	XCTAssertFalse([date isBetweenDate:startDate andDate:endDate]);
}

- (void)testIsBetweenDateReturnsTrueWhenSameAsStart {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *startDate = [date dateByAddingDays:0];
	NSDate *endDate = [date dateByAddingDays:1];
	
	XCTAssertTrue([date isBetweenDate:startDate andDate:endDate]);
}

- (void)testIsBetweenDateReturnsTrueWhenSameAsEnd {
	NSDate *date = [self.dateFormatter dateFromString:@"01-09-1979"];
	
	NSDate *startDate = [date dateBySubtractingDays:1];
	NSDate *endDate = [date dateByAddingDays:0];
	
	XCTAssertTrue([date isBetweenDate:startDate andDate:endDate]);
}

@end
