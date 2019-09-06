//
//  SimpleLogger.m
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SimpleLogger.h"
#import "SimpleLoggerDefaults.h"
#import "NSDate+SMA.h"
#import "FileManager.h"
#import "AmazonUploader.h"
#import <AWSS3/AWSS3.h>

@implementation SimpleLogger

+ (id)sharedLogger {
    static SimpleLogger *_sharedLogger = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedLogger = [[self alloc] init];
    });
    
    return _sharedLogger;
}

- (id)init {
    self = [super init];
    
    self.loggingEnabled = YES;
    self.retentionDays = kLoggerRetentionDaysDefault;
    self.filenameExtension = kLoggerFilenameExtension;
    self.folderLocation = kLoggerFilenameFolderLocation;
    
    [self initializeLogFormatter];
    [self initializeDateFormatter];
    
    return self;
}

- (void)initializeLogFormatter {
    self.logFormatter = [[NSDateFormatter alloc] init];
    self.logFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss z";
    // set the log date formatter locale so it is readable to English speakers
    [self.logFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
}

- (void)initializeDateFormatter {
    self.filenameFormatter = [[NSDateFormatter alloc] init];
    self.filenameFormatter.dateFormat = kLoggerFilenameDateFormat;
    // set the file name locale so it is readable to English speakers
    [self.filenameFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
}

+ (void)setLoggingEnabled:(BOOL)enabled {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.loggingEnabled = enabled;
}

+ (void)initWithAWSRegion:(AWSRegionType)region bucket:(NSString *)bucket accessToken:(NSString *)accessToken secret:(NSString *)secret {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    logger.awsRegion = region;
    logger.awsBucket = bucket;
    logger.awsAccessToken = accessToken;
    logger.awsSecret = secret;
    
    // initialize Amazon Upload Provider so it is ready for upload when needed
    [AmazonUploader initializeAmazonUploadProvider];
}

+ (void)addLogEvent:(NSString *)event {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    if (logger.loggingEnabled) {
        // only allow logging if enabled
        NSDate *date = [NSDate date];
        NSString *eventString = [logger eventString:event forDate:date];
        [FileManager writeLogEntry:eventString toFilename:[FileManager filenameForDate:date]];
        
        [logger truncateFilesBeyondRetentionForDate:date];
    }
}

+ (void)uploadAllFilesWithCompletion:(SLUploadCompletionHandler)completionHandler {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    if (![AmazonUploader amazonCredentialsSetCorrectly]) {
        // prevent upload if credentials not set
        completionHandler(NO, [NSError errorWithDomain:@"com.simplymadeapps.ios.simplelogger.aws.credentials.missing" code:999 userInfo:nil]);
        return;
    }
    
    if (logger.uploadInProgress) {
        // prevent multiple uploads from kicking off
        completionHandler(NO, nil);
        return;
    }
    
    NSArray *files = [logger logFiles];
    
    if (files) {
        [SimpleLogger resetLoggerForUpload];
        
        logger.uploadInProgress = YES;
        logger.uploadTotal = files.count;
        
        [SimpleLogger uploadFiles:files completionHandler:completionHandler];
    } else {
        logger.uploadInProgress = NO;
        completionHandler(NO, logger.uploadError);
    }
}

+ (void)uploadFiles:(NSArray *)files completionHandler:(SLUploadCompletionHandler)completionHandler {
    for (NSString *file in files) {
        [SimpleLogger uploadFile:file completionHandler:completionHandler];
    }
}

+ (void)uploadFile:(NSString *)file completionHandler:(SLUploadCompletionHandler)completionHandler {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    [AmazonUploader uploadFilePathToAmazon:file withBlock:^(AWSTask * _Nonnull task) {
        logger.currentUploadCount++;
        
        if (task.error) {
            logger.uploadError = task.error;
        }
        
        if (!task.error && ![FileManager filenameIsCurrentDay:file]) {
            // remove file on success upload
            [FileManager removeFile:file];
        }
        
        if (logger.currentUploadCount == logger.uploadTotal) {
            // final upload complete
            logger.uploadInProgress = NO;
            completionHandler(logger.uploadError == nil, logger.uploadError);
        }
    }];
}

+ (void)resetLoggerForUpload {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    logger.currentUploadCount = 0;
    logger.uploadError = nil;
}

+ (NSString *)logOutputForFileDate:(NSDate *)date {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSString *filePath = [docDirectory stringByAppendingPathComponent:[FileManager filenameForDate:date]];
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    return contents;
}

+ (void)removeAllLogFiles {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    [logger removeAllLogFiles];
}

#pragma mark - Instance Methods
- (void)removeAllLogFiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contents = [self logFiles];
    
    for (NSString *file in contents) {
        NSError *error;
        NSString *path = [docDirectory stringByAppendingPathComponent:file];
        [manager removeItemAtPath:path error:&error];
    }
}

- (NSArray *)logFiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contents = [manager contentsOfDirectoryAtPath:docDirectory error:nil];
    
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *file in contents) {
        if ([[file pathExtension] isEqualToString:self.filenameExtension]) {
            [files addObject:file];
        }
    }
    
    if (files.count > 0) {
        return files;
    } else {
        return nil;
    }
}

- (NSString *)eventString:(NSString *)string forDate:(NSDate *)date {
    NSString *dateString = [self.logFormatter stringFromDate:date];
    return [NSString stringWithFormat:@"[%@] %@", dateString, string];
}

#pragma mark - Private
- (void)truncateFilesBeyondRetentionForDate:(NSDate *)date {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    
    NSArray *contents = [self logFiles];
    
    NSDate *retainDate = [self lastRetentionDateForDate:date];
    
    for (NSString *file in contents) {
        NSDate *fileDate = [self.filenameFormatter dateFromString:[file stringByDeletingPathExtension]];
        
        if (![fileDate isBetweenDate:[retainDate minTime] andDate:[date maxTime]]) {
            // file is outside our retention period, delete file
            NSError *error;
            NSString *path = [docDirectory stringByAppendingPathComponent:file];
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        }
    }
}

- (NSDate *)lastRetentionDateForDate:(NSDate *)date {
    return [date dateBySubtractingDays:self.retentionDays - 1]; // drop one to preserve current day
}

@end
