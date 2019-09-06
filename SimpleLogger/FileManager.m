//
//  FileManager.m
//  SimpleLogger
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "FileManager.h"
#import "SimpleLogger.h"
#import "NSDate+SMA.h"

@implementation FileManager

+ (BOOL)filenameIsCurrentDay:(NSString *)filename {
    NSString *todayFilename = [FileManager filenameForDate:[NSDate date]];
    if ([todayFilename isEqualToString:filename]) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)filenameForDate:(NSDate *)date {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSString *filename = [logger.filenameFormatter stringFromDate:date];
    return [NSString stringWithFormat:@"%@.%@", filename, logger.filenameExtension];
}

+ (NSString *)fullFilePathForFilename:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    return [docDirectory stringByAppendingPathComponent:filename];
}

+ (void)writeLogEntry:(NSString *)log toFilename:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSString *path = [docDirectory stringByAppendingPathComponent:filename];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (fileExists) {
        NSString *newLineLog = [NSString stringWithFormat:@"\n%@", log];
        NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        [handle seekToEndOfFile];
        [handle writeData:[newLineLog dataUsingEncoding:NSUTF8StringEncoding]];
        [handle closeFile];
    } else {
        NSError *error;
        [log writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
}

+ (void)removeFile:(NSString *)filename {
    NSString *filePath = [FileManager fullFilePathForFilename:filename];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    [manager removeItemAtPath:filePath error:&error];
}

+ (void)truncateFilesBeyondRetentionForDate:(NSDate *)date {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSArray *contents = [FileManager logFiles];
    
    NSDate *retainDate = [FileManager lastRetentionDateForDate:date];
    
    for (NSString *file in contents) {
        NSDate *fileDate = [logger.filenameFormatter dateFromString:[file stringByDeletingPathExtension]];
        
        if (![fileDate isBetweenDate:[retainDate minTime] andDate:[date maxTime]]) {
            // file is outside our retention period, delete file
            NSError *error;
            NSString *path = [docDirectory stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
    }
}

+ (NSDate *)lastRetentionDateForDate:(NSDate *)date {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    return [date dateBySubtractingDays:logger.retentionDays - 1]; // drop one to preserve current day
}

+ (void)removeAllLogFiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contents = [FileManager logFiles];
    
    for (NSString *file in contents) {
        NSError *error;
        NSString *path = [docDirectory stringByAppendingPathComponent:file];
        [manager removeItemAtPath:path error:&error];
    }
}

+ (NSArray *)logFiles {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contents = [manager contentsOfDirectoryAtPath:docDirectory error:nil];
    
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *file in contents) {
        if ([[file pathExtension] isEqualToString:logger.filenameExtension]) {
            [files addObject:file];
        }
    }
    
    if (files.count > 0) {
        return files;
    } else {
        return nil;
    }
}

@end
