//
//  AmazonUploaderTests.m
//  SimpleLoggerTests
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "SimpleLoggerDefaults.h"
#import "AmazonUploader.h"

@interface AmazonUploader (UnitTests)
+ (NSString *)configKey;
+ (void)removePreviousTransferUtilityForKey:(NSString *)key;
@end

@interface AmazonUploaderTests : SLTestCase

@end

@implementation AmazonUploaderTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - amazonCredentialsSetCorrectly
- (void)testCredentialsOkReturnsYES {
    [SimpleLogger initWithAWSRegion:AWSRegionEUWest1 bucket:@"bucket" accessToken:@"token" secret:@"secret"];
    
    XCTAssertTrue([AmazonUploader amazonCredentialsSetCorrectly]);
}

- (void)testCredentialsOkReturnsFalse {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.awsRegion = 0;
    logger.awsBucket = nil;
    logger.awsAccessToken = nil;
    logger.awsSecret = nil;
    
    XCTAssertFalse([AmazonUploader amazonCredentialsSetCorrectly]);
}

- (void)testCredentialsOkReturnsFalseWithPartials {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.awsRegion = 0;
    logger.awsBucket = @"";
    logger.awsAccessToken = @"";
    logger.awsSecret = @"secret";
    
    XCTAssertFalse([AmazonUploader amazonCredentialsSetCorrectly]);
}

#pragma mark - initializeAmazonUploadProvider
- (void)testInitializeAmazonUploadProvider {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"bucket" accessToken:@"access" secret:@"secret"];
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.awsConfigurationKey = @"oldKey";
    
    id classMock = OCMClassMock([AmazonUploader class]);
    [[classMock expect] removePreviousTransferUtilityForKey:logger.awsConfigurationKey];
    [[[classMock expect] andReturn:@"configKey"] configKey];
    
    id providerMock = OCMClassMock([AWSStaticCredentialsProvider class]);
    [[[providerMock expect] andReturn:providerMock] alloc];
    (void)[[[providerMock expect] andReturn:providerMock] initWithAccessKey:@"access" secretKey:@"secret"];
    
    id transferMock = OCMClassMock([AWSS3TransferUtility class]);
    [[transferMock expect] registerS3TransferUtilityWithConfiguration:[OCMArg checkWithBlock:^BOOL(AWSServiceConfiguration *config) {
        XCTAssertEqual(config.regionType, logger.awsRegion);
        XCTAssertEqual(config.credentialsProvider, providerMock);
        return YES;
    }] forKey:@"configKey"];
    
    [AmazonUploader initializeAmazonUploadProvider];
    
    [self verifyAndStopMocking:classMock];
    [self verifyAndStopMocking:providerMock];
    [self verifyAndStopMocking:transferMock];
}

#pragma mark - configKey
- (void)testConfigKey {
    NSUUID *uuid = [NSUUID UUID];
    
    id uuidMock = OCMPartialMock(uuid);
    [[[uuidMock expect] andReturn:@"testuuid"] UUIDString];
    
    id classMock = OCMClassMock([NSUUID class]);
    [[[classMock expect] andReturn:uuid] UUID];
    
    XCTAssertTrue([[AmazonUploader configKey] containsString:@"SimpleLogger.AWS.ConfigKey.testuuid"]);
    [self verifyAndStopMocking:uuidMock];
    [self verifyAndStopMocking:classMock];
}

#pragma mark - removePreviousTransferUtilityForKey:
- (void)testRemovePreviousTransferUtilityIfNeeded_WithKey {
    id transferMock = OCMClassMock([AWSS3TransferUtility class]);
    [[transferMock expect] removeS3TransferUtilityForKey:@"configkey"];
    
    [AmazonUploader removePreviousTransferUtilityForKey:@"configkey"];
    
    [self verifyAndStopMocking:transferMock];
}

- (void)testRemovePreviousTransferUtilityIfNeeded_NilKey {
    id transferMock = OCMClassMock([AWSS3TransferUtility class]);
    [[transferMock reject] removeS3TransferUtilityForKey:[OCMArg any]];
    
    [AmazonUploader removePreviousTransferUtilityForKey:nil];
    
    [self verifyAndStopMocking:transferMock];
}

#pragma mark - bucketFileLocationForFilename:
- (void)testAmazonBucketKeySetsCorrectly {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.folderLocation = kLoggerFilenameFolderLocation;
    
    NSString *filePath = [AmazonUploader bucketFileLocationForFilename:@"test.log"];
    
    XCTAssertNotNil(filePath);
    XCTAssertEqualObjects(filePath, @"SimpleLogger/test.log");
}

#pragma mark - uploadFilePathToAmazon:withBlock:
- (void)testUploadFileToAmazonReturnsBlock {
    [SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"bucket" accessToken:@"access" secret:@"secret"];
    
    AWSTask *task = [[AWSTask alloc] init];
    NSError *error = [NSError errorWithDomain:@"com.test.error" code:123 userInfo:nil];
    id taskMock = OCMPartialMock(task);
    [[[taskMock stub] andReturn:error] error];
    AWSS3TransferUtility *utility = [AWSS3TransferUtility S3TransferUtilityForKey:[SimpleLogger sharedLogger].awsConfigurationKey];
    XCTAssertNotNil(utility);
    id transferMock = OCMClassMock([AWSS3TransferUtility class]);
    [[[transferMock stub] andReturn:utility] S3TransferUtilityForKey:@"SimpleLoggerTransferUtility"];
    id utilityMock = OCMPartialMock(utility);
    [[[utilityMock stub] andReturn:taskMock] uploadFile:[OCMArg any] bucket:[OCMArg any] key:[OCMArg any] contentType:[OCMArg any] expression:nil completionHandler:[OCMArg invokeBlockWithArgs:taskMock, error, nil]];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [AmazonUploader uploadFilePathToAmazon:@"test.log" withBlock:^(AWSTask * _Nonnull task) {
        [expect fulfill];
    }];
    
    [self verifyAndStopMocking:taskMock];
    [self verifyAndStopMocking:transferMock];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
