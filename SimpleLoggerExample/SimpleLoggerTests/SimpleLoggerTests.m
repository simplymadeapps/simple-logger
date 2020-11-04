//
//  SimpleLoggerTests.m
//  SimpleLoggerTests
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "SimpleLoggerDefaults.h"
#import "FileManager.h"
#import "NSDate+SMA.h"
#import <AWSS3/AWSS3.h>

@interface SLAWSTask : AWSTask
@property (nonatomic, strong, readwrite) NSError *myerror;
@end

@implementation SLAWSTask
- (NSError *)getError {
    return self.myerror;
}
@end

@interface SimpleLoggerTests : SLTestCase

@end

@implementation SimpleLoggerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - sharedLogger
- (void)testSharedLoggerNotNil {
    XCTAssertNotNil([SimpleLogger sharedLogger]);
}

#pragma mark - init
- (void)testLoggerInitsWithCorrectDefaults {
    SimpleLogger *logger = [[SimpleLogger alloc] init];
    
    XCTAssertNotNil(logger.logFormatter);
    XCTAssertNotNil(logger.filenameFormatter);
    XCTAssertEqual(logger.retentionDays, kLoggerRetentionDaysDefault);
    XCTAssertEqualObjects(logger.filenameExtension, kLoggerFilenameExtension);
}

#pragma mark - initWithAWSRegion:bucket:accessToken:secret:
- (void)testAmazonInitStoresValuesCorrectly {
    id uploadMock = OCMClassMock([AmazonUploader class]);
    [[uploadMock expect] initializeAmazonUploadProvider];
    
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    XCTAssertEqual(logger.awsRegion, AWSRegionUSEast1);
    XCTAssertEqualObjects(logger.awsBucket, @"test_bucket");
    XCTAssertEqualObjects(logger.awsAccessToken, @"test_token");
    XCTAssertEqualObjects(logger.awsSecret, @"test_secret");
    [self verifyAndStopMocking:uploadMock];
}

#pragma mark - addLogEvent:
- (void)testLogEvent {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [NSDate date];
    
    [SimpleLogger addLogEvent:@"my test string"];
    
    NSString *log = [SimpleLogger logOutputForFileDate:date];
    NSString *compare = [NSString stringWithFormat:@"[%@] my test string", [logger.logFormatter stringFromDate:date]];
    XCTAssertNotNil(log);
    XCTAssertEqualObjects(log, compare);
}

- (void)testLogEventAppendsNewLines {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [NSDate date];
    
    [SimpleLogger addLogEvent:@"my test string"];
    [SimpleLogger addLogEvent:@"other test string"];
    
    NSString *log = [SimpleLogger logOutputForFileDate:date];
    NSString *compare = [NSString stringWithFormat:@"[%@] my test string\n[%@] other test string", [logger.logFormatter stringFromDate:date], [logger.logFormatter stringFromDate:date]];
    XCTAssertNotNil(log);
    XCTAssertEqualObjects(log, compare);
}

- (void)testLogEventSkippedWhenDisabled {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [NSDate date];
    
    [SimpleLogger addLogEvent:@"my test string"];
    
    logger.loggingEnabled = NO;
    
    [SimpleLogger addLogEvent:@"other test string"];
    
    NSString *log = [SimpleLogger logOutputForFileDate:date];
    NSString *compare = [NSString stringWithFormat:@"[%@] my test string", [logger.logFormatter stringFromDate:date]];
    XCTAssertNotNil(log);
    XCTAssertEqualObjects(log, compare);
}

#pragma mark - eventString:forDate:
- (void)testEventStringGetsFormattedCorrectly_DefaultLocale {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSString *dateString = [logger.logFormatter stringFromDate:[self testDate]];
    NSString *eventString = [logger eventString:@"test event" forDate:[self testDate]];
    NSString *testString = [NSString stringWithFormat:@"[%@] test event", dateString];
    
    XCTAssertNotNil(eventString);
    XCTAssertEqualObjects(eventString, testString);
}

- (void)testEventStringGetsFormattedCorrectly_NonENLocale {
    id localeMock = OCMClassMock([NSLocale class]);
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"ar"];
    [[[localeMock stub] andReturn:locale] currentLocale];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSString *dateString = [logger.logFormatter stringFromDate:[self testDate]];
    NSString *eventString = [logger eventString:@"test event" forDate:[self testDate]];
    NSString *testString = [NSString stringWithFormat:@"[%@] test event", dateString];
    
    XCTAssertNotNil(eventString);
    XCTAssertEqualObjects(eventString, testString);
    
    [self verifyAndStopMocking:localeMock];
}

#pragma mark - removeAllLogFiles
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

#pragma mark - uploadAllFilesWithCompletion:
- (void)testUploadRemovesPreviousDaysFiles {
    [SimpleLogger addLogEvent:@"Create file for today"];
    [self saveDummyFiles:2];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    // should have 3 files saved
    XCTAssertEqual(content.count, 3);
    
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    __block id mock = OCMClassMock([AmazonUploader class]);
    [[mock stub] uploadFilePathToAmazon:[OCMArg any] withBlock:[OCMArg checkWithBlock:^BOOL(SLAmazonTaskUploadCompletionHandler handler) {
        SLAWSTask *task = [[SLAWSTask alloc] init];
        handler(task);
        return YES;
    }]];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
        
        // should have 1 file saved
        XCTAssertEqual(content.count, 1);
        
        [self verifyAndStopMocking:mock];
        
        [expect fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUploadFilesFailsWithoutAWSCredentialsWithCompletion {
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload Errors"];
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        
        [expect fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUploadFilesWithCompletionWhileInProgress {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.uploadInProgress = YES;
    logger.currentUploadCount = 1;
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload In Progress"];
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success);
        XCTAssertNil(error);
        XCTAssertEqual(logger.currentUploadCount, 1);
        [expect fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUploadFilesWithCompletionWhileInProgressNoHandler {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.uploadInProgress = YES;
    logger.currentUploadCount = 1;
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];
    
    [tester waitForAnimationsToFinish];
    
    XCTAssertTrue(logger.currentUploadCount == 1);
}

- (void)testUploadFilesWithNoFilesAndCompletion {
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success);
        XCTAssertNil(error);
        
        [expect fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUploadFilesWithNoFilesNoCompletion {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];
    
    XCTAssertFalse([[SimpleLogger sharedLogger] uploadInProgress]);
}

- (void)testUploadFilesInProgress {
    // tests scenario that can never happen, but satisfies codecov
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.uploadInProgress = YES;
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(logger.uploadInProgress);
    }];
}

- (void)testUploadFilesWithEmptyFiles {
    // tests scenario that can never happen, but satisfies codecov
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    id mock = OCMClassMock([FileManager class]);
    [[[mock stub] andReturn:@[]] logFiles];
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(logger.uploadInProgress);
    }];
    
    [mock stopMocking];
}

- (void)testUploadFilesWithCompletionSuccess {
    [self saveDummyFiles:2];
    
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    __block id mock = OCMClassMock([AmazonUploader class]);
    [[mock stub] uploadFilePathToAmazon:[OCMArg any] withBlock:[OCMArg checkWithBlock:^BOOL(SLAmazonTaskUploadCompletionHandler handler) {
        SLAWSTask *task = [[SLAWSTask alloc] init];
        handler(task);
        return YES;
    }]];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        XCTAssertFalse(logger.uploadInProgress);
        
        [self verifyAndStopMocking:mock];
        
        [expect fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testUploadFilesWithCompletionError {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    AWSTask *task = [[AWSTask alloc] init];
    __block id taskMock = OCMPartialMock(task);
    [[[taskMock stub] andReturn:[NSError errorWithDomain:@"com.test.error" code:123 userInfo:nil]] error];
    
    __block id mock = OCMClassMock([AmazonUploader class]);
    [[mock stub] uploadFilePathToAmazon:[OCMArg any] withBlock:[OCMArg checkWithBlock:^BOOL(SLAmazonTaskUploadCompletionHandler handler) {
        handler(taskMock);
        return YES;
    }]];
    
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    [self saveDummyFiles:1];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        XCTAssertFalse(logger.uploadInProgress);
        
        [self verifyAndStopMocking:mock];
        
        [taskMock stopMocking];
        taskMock = nil;
        
        [expect fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testFileDateFormatChangeDeletesFiles {
    [self saveDummyFiles:8];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.retentionDays = 5;
    logger.filenameFormatter.dateFormat = @"MM-dd-yyyy";
    
    [SimpleLogger addLogEvent:@"Log event with new filename"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    XCTAssertEqual(content.count, 1);
    
    [SimpleLogger removeAllLogFiles];
}

@end
