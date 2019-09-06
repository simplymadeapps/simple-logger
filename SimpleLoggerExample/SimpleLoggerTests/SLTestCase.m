//
//  SLTestCase.m
//  SimpleLogger
//
//  Created by Bill Burgess on 8/7/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SLTestCase.h"
#import "FileManager.h"
#import "SimpleLoggerDefaults.h"
#import "NSDate+SMA.h"
#import <AWSS3/AWSS3.h>

@implementation SLTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [SimpleLogger removeAllLogFiles];
    [self resetLoggerUploadInfo];
    
    UIApplication.sharedApplication.keyWindow.layer.speed = 100; // ludicrous speed
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
    NSDate *date = [self testDate];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    while (count > 0) {
        NSError *error;
        NSString *testLog = @"test log";
        NSString *filename = [FileManager filenameForDate:[date dateBySubtractingDays:count]];
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

- (void)resetLoggerUploadInfo {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    logger.loggingEnabled = YES;
    logger.filenameFormatter.dateFormat = kLoggerFilenameDateFormat;
    logger.retentionDays = kLoggerRetentionDaysDefault;
    logger.uploadInProgress = NO;
    logger.uploadTotal = 0;
    logger.currentUploadCount = 0;
    logger.uploadError = nil;
    logger.folderLocation = kLoggerFilenameFolderLocation;
    logger.awsRegion = 0;
    logger.awsBucket = nil;
    logger.awsAccessToken = nil;
    logger.awsSecret = nil;
}

- (void)verifyAndStopMocking:(id)mock {
    [mock verify];
    [mock stopMocking];
    mock = nil;
}

@end
