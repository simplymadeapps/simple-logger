//
//  SimpleLogger.h
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import "AmazonUploader.h"

@interface SimpleLogger : NSObject

/// Logging allowed to write to file
@property (nonatomic, assign) BOOL loggingEnabled;
/// Number of days worth of logs to keep
@property (nonatomic, assign) NSInteger retentionDays;
/// Log statement date formatter
@property (nonatomic, strong, nonnull) NSDateFormatter *logFormatter;
/// Filename date formatter
@property (nonatomic, strong, nonnull) NSDateFormatter *filenameFormatter;
/// Filename extension
@property (nonatomic, strong, nonnull) NSString *filenameExtension;
/// Filename folder assignment location
@property (nonatomic, strong, nonnull) NSString *folderLocation;

/// Amazon S3 region
@property (nonatomic, assign) AWSRegionType awsRegion;
/// Amazon S3 bucket
@property (nonatomic, strong, nullable) NSString *awsBucket;
/// Amazon S3 access token
@property (nonatomic, strong, nullable) NSString *awsAccessToken;
/// Amazon S3 secret
@property (nonatomic, strong, nullable) NSString *awsSecret;
/// Amazon S3 Configuration Key
@property (nonatomic, strong, nullable) NSString *awsConfigurationKey;

/// currently uploading files
@property (nonatomic, assign) BOOL uploadInProgress;
/// file upload total
@property (nonatomic, assign) NSInteger uploadTotal;
/// current file upload count
@property (nonatomic, assign) NSInteger currentUploadCount;
/// file upload error
@property (nonatomic, strong, nullable) NSError *uploadError;

/// Shared instance of SimpleLogger
+ (instancetype _Nonnull)sharedLogger;

/**
Initialize shared logger with Amazon region, bucket, and credentials
@param region Amazon S3 region
@param bucket Amazon S3 bucket
@param accessToken Amazon S3 access token
@param secret Amazon S3 secret
*/
+ (void)initWithAWSRegion:(AWSRegionType)region bucket:(NSString * _Nonnull)bucket accessToken:(NSString * _Nonnull)accessToken secret:(NSString * _Nonnull)secret;

/**
Logs event to daily file with current system date time
@param event Event string to be logged
*/
+ (void)addLogEvent:(NSString * _Nonnull)event;
/**
Uploads all current log files to S3
*/
+ (void)uploadAllFilesWithCompletion:(SLUploadCompletionHandler _Nonnull)completionHandler;
/**
File output for specified date
@param date Date for log output
*/
+ (NSString * _Nullable)logOutputForFileDate:(NSDate * _Nonnull)date;

/// Removes all saved log files matching file extension
+ (void)removeAllLogFiles;

@end
