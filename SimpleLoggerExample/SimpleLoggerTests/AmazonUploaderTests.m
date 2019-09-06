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

@interface AmazonUploaderTests : SLTestCase

@end

@implementation AmazonUploaderTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

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
    [SimpleLogger initWithAWSRegion:0 bucket:@"" accessToken:@"" secret:@"secret"];
    
    XCTAssertFalse([AmazonUploader amazonCredentialsSetCorrectly]);
}

- (void)testAmazonBucketKeySetsCorrectly {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.folderLocation = kLoggerFilenameFolderLocation;
    
    NSString *filePath = [AmazonUploader bucketFileLocationForFilename:@"test.log"];
    
    XCTAssertNotNil(filePath);
    XCTAssertEqualObjects(filePath, @"SimpleLogger/test.log");
}

- (void)testUploadFileToAmazonReturnsBlock {
    AWSTask *task = [[AWSTask alloc] init];
    NSError *error = [NSError errorWithDomain:@"com.test.error" code:123 userInfo:nil];
    id taskMock = OCMPartialMock(task);
    [[[taskMock stub] andReturn:error] error];
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    id transferMock = OCMPartialMock(transferUtility);
    //[[[taskMock stub] andReturn:taskMock] continueWithExecutor:[OCMArg any] withBlock:[OCMArg invokeBlockWithArgs:taskMock, nil]];
    [[[transferMock stub] andReturn:taskMock] uploadFile:[OCMArg any] bucket:[OCMArg any] key:[OCMArg any] contentType:[OCMArg any] expression:nil completionHandler:[OCMArg invokeBlockWithArgs:taskMock, error, nil]];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Upload All Files"];
    
    [AmazonUploader uploadFilePathToAmazon:@"test.log" withBlock:^(AWSTask * _Nonnull task) {
        [expect fulfill];
    }];
    
    [self verifyAndStopMocking:taskMock];
    [self verifyAndStopMocking:transferMock];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
