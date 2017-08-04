//
//  SimpleLogger.h
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleLoggerDefaults.h"

@interface SimpleLogger : NSObject

/// Number of days worth of logs to keep
@property (nonatomic, assign) NSInteger retentionDays;
/// Log statement date formatter
@property (nonatomic, strong, nonnull) NSDateFormatter *logFormatter;
/// Filename date formatter
@property (nonatomic, strong, nonnull) NSDateFormatter *filenameFormatter;
/// Filename extension
@property (nonatomic, strong, nonnull) NSString *filenameExtension;

/// Amazon S3 region
@property (nonatomic, strong, nullable) NSString *awsRegion;
/// Amazon S3 bucket
@property (nonatomic, strong, nullable) NSString *awsBucket;
/// Amazon S3 access token
@property (nonatomic, strong, nullable) NSString *awsAccessToken;
/// Amazon S3 secret
@property (nonatomic, strong, nullable) NSString *awsSecret;

/// Shared instance of SimpleLogger
+ (instancetype _Nonnull)sharedLogger;

/**
Initialize shared logger with Amazon region, bucket, and credentials
@param region Amazon S3 region
@param bucket Amazon S3 bucket
@param accessToken Amazon S3 access token
@param secret Amazon S3 secret
*/
+ (void)initWithAWSRegion:(NSString * _Nonnull)region bucket:(NSString * _Nonnull)bucket accessToken:(NSString * _Nonnull)accessToken secret:(NSString * _Nonnull)secret;

/**
Logs event to daily file with current system date time
@param event Event string to be logged
*/
+ (void)logEvent:(NSString * _Nonnull)event;

@end
