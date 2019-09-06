//
//  FileManagerTests.m
//  SimpleLoggerTests
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "FileManager.h"
#import "NSDate+SMA.h"

@interface FileManagerTests : SLTestCase

@end

@implementation FileManagerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testFilenameIsCurrentDayReturnsYES {
    NSDate *date = [NSDate date];
    NSString *filename = [FileManager filenameForDate:date];
    
    XCTAssertTrue([FileManager filenameIsCurrentDay:filename]);
}

- (void)testFilenameIsCurrentDayReturnsNO {
    NSDate *date = [[NSDate date] dateBySubtractingDays:1];
    NSString *filename = [FileManager filenameForDate:date];
    
    XCTAssertFalse([FileManager filenameIsCurrentDay:filename]);
}

- (void)testFullFilePathReturnsCorrectly {
    NSString *filePath = [FileManager fullFilePathForFilename:@"test.log"];
    
    XCTAssertNotNil(filePath);
}

- (void)testFilenameForDateReturnsCorrectly {
    NSDate *date = [self testDate];
    NSString *filename = [FileManager filenameForDate:date];
    
    XCTAssertNotNil(filename);
    XCTAssertEqualObjects(filename, @"2017-07-15.log");
}

- (void)testFilenameForDateReturnsEnglishFilenameWhenLocaleDifferent {
    id localeMock = OCMClassMock([NSLocale class]);
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"ar"];
    [[[localeMock stub] andReturn:locale] currentLocale];
    
    NSDate *date = [self testDate];
    NSString *filename = [FileManager filenameForDate:date];
    
    XCTAssertNotNil(filename);
    XCTAssertEqualObjects(filename, @"2017-07-15.log");
    
    [self verifyAndStopMocking:localeMock];
}

- (void)testDeleteFileWorks {
    [SimpleLogger addLogEvent:@"Create log file for today"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSError *error;
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    // should have 1 file saved
    XCTAssertEqual(content.count, 1);
    
    [FileManager removeFile:[FileManager filenameForDate:[NSDate date]]];
    
    content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
    
    XCTAssertEqual(content.count, 0);
}

@end
