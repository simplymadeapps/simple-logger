//
//  FileManagerTests.m
//  SimpleLoggerTests
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "FileManager.h"

@interface FileManagerTests : SLTestCase

@end

@implementation FileManagerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testFullFilePathReturnsCorrectly {
    NSString *filePath = [FileManager fullFilePathForFilename:@"test.log"];
    
    XCTAssertNotNil(filePath);
}

@end
