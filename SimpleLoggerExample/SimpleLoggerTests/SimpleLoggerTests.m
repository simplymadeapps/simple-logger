//
//  SimpleLoggerTests.m
//  SimpleLoggerTests
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "SimpleLoggerDefaults.h"
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
    [SimpleLogger removeAllLogFiles];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.uploadInProgress = NO;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [SimpleLogger removeAllLogFiles];
    [self deleteRegularFiles];
    
    [super tearDown];
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

- (void)testSetLoggingEnabledWorksCorrectly {
    [SimpleLogger setLoggingEnabled:NO];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    XCTAssertFalse(logger.loggingEnabled);
    
    [SimpleLogger setLoggingEnabled:YES];
    
    XCTAssertTrue(logger.loggingEnabled);
}

- (void)testAmazonInitStoresValuesCorrectly {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test_bucket" accessToken:@"test_token" secret:@"test_secret"];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    XCTAssertNotNil(logger);
    XCTAssertNotNil(logger.awsBucket);
    XCTAssertNotNil(logger.awsAccessToken);
    XCTAssertNotNil(logger.awsSecret);
    
    XCTAssertEqual(logger.awsRegion, AWSRegionUSEast1);
    XCTAssertEqualObjects(logger.awsBucket, @"test_bucket");
    XCTAssertEqualObjects(logger.awsAccessToken, @"test_token");
    XCTAssertEqualObjects(logger.awsSecret, @"test_secret");
}

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
    
    [SimpleLogger setLoggingEnabled:NO];
    
    [SimpleLogger addLogEvent:@"other test string"];
    
    NSString *log = [SimpleLogger logOutputForFileDate:date];
    NSString *compare = [NSString stringWithFormat:@"[%@] my test string", [logger.logFormatter stringFromDate:date]];
    XCTAssertNotNil(log);
    XCTAssertEqualObjects(log, compare);
}

- (void)testEventStringGetsFormattedCorrectly_DefaultLocale {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSString *eventString = [logger eventString:@"test event" forDate:[self testDate]];
    
    XCTAssertNotNil(eventString);
    XCTAssertEqualObjects(eventString, @"[2017-07-15 10:10:00 CDT] test event");
}

- (void)testEventStringGetsFormattedCorrectly_NonENLocale {
    id localeMock = OCMClassMock([NSLocale class]);
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"ar"];
    [[[localeMock stub] andReturn:locale] currentLocale];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSString *eventString = [logger eventString:@"test event" forDate:[self testDate]];
    
    XCTAssertNotNil(eventString);
    XCTAssertEqualObjects(eventString, @"[2017-07-15 10:10:00 CDT] test event");
    
    [self verifyAndStopMocking:localeMock];
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

- (void)testDeleteFileWorks {
    [SimpleLogger addLogEvent:@"Create log file for today"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    // should have 1 file saved
    XCTAssertEqual(content.count, 1);
    
    [logger removeFile:[logger filenameForDate:[NSDate date]]];
    
    content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    XCTAssertEqual(content.count, 0);
}

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
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    __block id mock = OCMPartialMock(logger);
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
        
        [mock verify];
        [mock stopMocking];
        mock = nil;
        
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
    
    id mock = OCMPartialMock(logger);
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
    
    __block id mock = OCMPartialMock(logger);
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
    
    __block id mock = OCMPartialMock(logger);
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

- (void)testUploadFileToAmazonReturnsBlock {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    AWSTask *task = [[AWSTask alloc] init];
    NSError *error = [NSError errorWithDomain:@"com.test.error" code:123 userInfo:nil];
    id taskMock = OCMPartialMock(task);
    [[[taskMock stub] andReturn:error] error];
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    id transferMock = OCMPartialMock(transferUtility);
    //[[[taskMock stub] andReturn:taskMock] continueWithExecutor:[OCMArg any] withBlock:[OCMArg invokeBlockWithArgs:taskMock, nil]];
    [[[transferMock stub] andReturn:taskMock] uploadFile:[OCMArg any] bucket:[OCMArg any] key:[OCMArg any] contentType:[OCMArg any] expression:nil completionHandler:[OCMArg invokeBlockWithArgs:taskMock, error, nil]];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [logger uploadFilePathToAmazon:@"test.log" withBlock:^(AWSTask * _Nonnull task) {
        [expect fulfill];
    }];
    
    [taskMock verify];
    [taskMock stopMocking];
    taskMock = nil;
    
    [transferMock verify];
    [transferMock stopMocking];
    transferMock = nil;
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
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

- (void)testFileTruncationWhenFilesNil {
    [self saveRegularFiles:1];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    id mock = OCMPartialMock(fm);
    [[[mock stub] andReturn:nil] contentsOfDirectoryAtPath:[OCMArg any] error:[OCMArg anyObjectRef]];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    [logger truncateFilesBeyondRetentionForDate:[self testDate]];
    
    [mock verify];
    [mock stopMocking];
    mock = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    XCTAssertEqual(content.count, 1);
}

- (void)testFileTruncationWhenDifferentExtension {
    [self saveDummyFiles:8];
    [self saveRegularFiles:2];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    // should have 10 files saved
    XCTAssertEqual(content.count, 10);
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    [logger truncateFilesBeyondRetentionForDate:[self testDate]];
    
    content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    XCTAssertEqual(content.count, 8);
}

- (void)testAmazonBucketKeySetsCorrectly {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.folderLocation = kLoggerFilenameFolderLocation;
    
    NSString *filePath = [logger bucketFileLocationForFilename:@"test.log"];
    
    XCTAssertNotNil(filePath);
    XCTAssertEqualObjects(filePath, @"SimpleLogger/test.log");
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

- (void)testFilenameIsCurrentDayReturnsYES {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [NSDate date];
    NSString *filename = [logger filenameForDate:date];
    
    XCTAssertTrue([logger filenameIsCurrentDay:filename]);
}

- (void)testFilenameIsCurrentDayReturnsNO {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [[NSDate date] dateBySubtractingDays:1];
    NSString *filename = [logger filenameForDate:date];
    
    XCTAssertFalse([logger filenameIsCurrentDay:filename]);
}

#pragma mark - Helpers
- (void)testFilenameForDateReturnsCorrectly {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [self testDate];
    NSString *filename = [logger filenameForDate:date];
    
    XCTAssertNotNil(filename);
    XCTAssertEqualObjects(filename, @"2017-07-15.log");
}

- (void)testFilenameForDateReturnsEnglishFilenameWhenLocaleDifferent {
    id localeMock = OCMClassMock([NSLocale class]);
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"ar"];
    [[[localeMock stub] andReturn:locale] currentLocale];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    NSDate *date = [self testDate];
    NSString *filename = [logger filenameForDate:date];
    
    XCTAssertNotNil(filename);
    XCTAssertEqualObjects(filename, @"2017-07-15.log");
    
    [self verifyAndStopMocking:localeMock];
}

- (void)testCredentialsOkReturnsYES {
    [SimpleLogger initWithAWSRegion:AWSRegionEUWest1 bucket:@"bucket" accessToken:@"token" secret:@"secret"];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    XCTAssertTrue([logger amazonCredentialsSetCorrectly]);
}

- (void)testCredentialsOkReturnsFalse {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    XCTAssertFalse([logger amazonCredentialsSetCorrectly]);
}

- (void)testCredentialsOkReturnsFalseWithPartials {
    [SimpleLogger initWithAWSRegion:0 bucket:@"" accessToken:@"" secret:@"secret"];
    
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    XCTAssertFalse([logger amazonCredentialsSetCorrectly]);
}

@end
