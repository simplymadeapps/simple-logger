//
//  FileManager.h
//  SimpleLogger
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManager : NSObject

+ (BOOL)filenameIsCurrentDay:(NSString *)filename;
+ (NSString *)filenameForDate:(NSDate *)date;
+ (NSString *)fullFilePathForFilename:(NSString *)filename;
+ (void)writeLogEntry:(NSString *)log toFilename:(NSString *)filename;
+ (void)removeFile:(NSString *)filename;
+ (void)truncateFilesBeyondRetentionForDate:(NSDate *)date;
+ (NSDate *)lastRetentionDateForDate:(NSDate *)date;
+ (void)removeAllLogFiles;
+ (NSArray *)logFiles;

@end
