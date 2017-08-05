//
//  SimpleLoggerTests.m
//  SimpleLoggerTests
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SimpleLogger.h"

@interface SimpleLogger (UnitTests)
// instance
- (NSString *)eventString:(NSString *)string forDate:(NSDate *)date;
// private
- (void)truncateFilesBeyondRetentionForDate:(NSDate *)date;
- (NSDate *)lastRetentionDateForDate:(NSDate *)date;
// helpers
- (NSString *)filenameForDate:(NSDate *)date;
@end

@interface SimpleLoggerTests : XCTestCase

@end

@implementation SimpleLoggerTests

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

- (NSDate *)testDate {
	NSDate *date = [NSDate date];
	unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *comp = [cal components:flags fromDate:date];
	[comp setYear:2017];
	[comp setMonth:7];
	[comp setDay:15];
	[comp setHour:10];
	[comp setMinute:10];
	
	return [cal dateFromComponents:comp];
}

- (void)saveDummyFiles:(NSInteger)count {
	// save empty test files
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	NSDate *date = [self testDate];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	
	while (count > 0) {
		NSError *error;
		NSString *testLog = @"test log";
		NSString *filename = [logger filenameForDate:[date dateBySubtractingDays:count]];
		NSString *path = [docDirectory stringByAppendingPathComponent:filename];
		[testLog writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
		
		count--;
	}
}

- (void)saveRegularFiles:(NSInteger)count {
	// save empty test files
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	
	while (count > 0) {
		NSError *error;
		NSString *testLog = @"test log";
		NSString *filename = [NSString stringWithFormat:@"test%li.test", count];
		NSString *path = [docDirectory stringByAppendingPathComponent:filename];
		[testLog writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
		
		count--;
	}
}

- (void)deleteRegularFiles {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *contents = [manager contentsOfDirectoryAtPath:docDirectory error:nil];
	
	for (NSString *file in contents) {
		if ([[file pathExtension] isEqualToString:@"test"]) {
			NSError *error;
			NSString *path = [docDirectory stringByAppendingPathComponent:file];
			[manager removeItemAtPath:path error:&error];
		}
	}
}

#pragma mark - Public Methods
- (void)testSharedLoggerNotNil {
	XCTAssertNotNil([SimpleLogger sharedLogger]);
}

- (void)testLoggerInitsWithCorrectDefaults {
	SimpleLogger *logger = [[SimpleLogger alloc] init];
	
	XCTAssertNotNil(logger.logFormatter);
	XCTAssertNotNil(logger.filenameFormatter);
	XCTAssertEqual(logger.retentionDays, kLoggerRetentionDaysDefault);
	XCTAssertEqualObjects(logger.filenameExtension, kLoggerFilenameExtension);
}

- (void)testAmazonInitStoresValuesCorrectly {
	[SimpleLogger initWithAWSRegion:@"test_region" bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
	
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	XCTAssertNotNil(logger);
	XCTAssertNotNil(logger.awsRegion);
	XCTAssertNotNil(logger.awsBucket);
	XCTAssertNotNil(logger.awsAccessToken);
	XCTAssertNotNil(logger.awsSecret);
	
	XCTAssertEqualObjects(logger.awsRegion, @"test_region");
	XCTAssertEqualObjects(logger.awsBucket, @"test_bucket");
	XCTAssertEqualObjects(logger.awsAccessToken, @"test_token");
	XCTAssertEqualObjects(logger.awsSecret, @"test_secret");
}

- (void)testLogEvent {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	NSDate *date = [NSDate date];
	
	[SimpleLogger logEvent:@"my test string"];
	
	NSString *log = [SimpleLogger logOutputForFileDate:date];
	NSString *compare = [NSString stringWithFormat:@"[%@] my test string", [logger.logFormatter stringFromDate:date]];
	XCTAssertNotNil(log);
	XCTAssertEqualObjects(log, compare);
}

- (void)testLogEventAppendsNewLines {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	NSDate *date = [NSDate date];
	
	[SimpleLogger logEvent:@"my test string"];
	[SimpleLogger logEvent:@"other test string"];
	
	NSString *log = [SimpleLogger logOutputForFileDate:date];
	NSString *compare = [NSString stringWithFormat:@"[%@] my test string\n[%@] other test string", [logger.logFormatter stringFromDate:date], [logger.logFormatter stringFromDate:date]];
	XCTAssertNotNil(log);
	XCTAssertEqualObjects(log, compare);
}

- (void)testEventStringGetsFormattedCorrectly {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	NSString *eventString = [logger eventString:@"test event" forDate:[self testDate]];
	
	XCTAssertNotNil(eventString);
	XCTAssertEqualObjects(eventString, @"[2017-07-15 10:10:00] test event");
}

- (void)testRemoveAllFilesWorksCorrectly {	
	[self saveDummyFiles:5];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	
	NSError *error;
	NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	// should have 5 files saved
	XCTAssertEqual(content.count, 5);
	
	[SimpleLogger removeAllLogFiles];
	
	content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	XCTAssertEqual(content.count, 0);
}

- (void)testRemoveAllFilesKeepsNonLogFiles {
	[self saveDummyFiles:1];
	[self saveRegularFiles:2];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	
	NSError *error;
	NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	// should have 3 files saved
	XCTAssertEqual(content.count, 3);
	
	[SimpleLogger removeAllLogFiles];
	
	content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	XCTAssertEqual(content.count, 2);
}

#pragma mark - Private Methods
- (void)testLastRetentionDateReturnsCorrectly {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	NSDate *now = [self testDate];
	NSDate *lastRetainDate = [logger lastRetentionDateForDate:now];
	
	XCTAssertNotNil(lastRetainDate);
	NSString *dateString = [logger.filenameFormatter stringFromDate:lastRetainDate];
	XCTAssertNotNil(dateString);
	XCTAssertEqualObjects(dateString, @"2017-07-09");
}

- (void)testFileTruncationWorksCorrectly {
	[self saveDummyFiles:8];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	
	NSError *error;
	NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	// should have 8 files saved
	XCTAssertEqual(content.count, 8);
	
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	[logger truncateFilesBeyondRetentionForDate:[self testDate]];
	
	content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	XCTAssertEqual(content.count, 6); // doesn't make file for current day, so dropping 2
}

#pragma mark - Helpers
- (void)testFilenameForDateReturnsCorrectly {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	NSDate *date = [self testDate];
	NSString *filename = [logger filenameForDate:date];
	
	XCTAssertNotNil(filename);
	XCTAssertEqualObjects(filename, @"2017-07-15.log");
}

@end
