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
	self.logFormatter = [[NSDateFormatter alloc] init];
	self.logFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss z";
	self.filenameFormatter = [[NSDateFormatter alloc] init];
	self.filenameFormatter.dateFormat = kLoggerFilenameDateFormat;
	self.filenameExtension = kLoggerFilenameExtension;
	self.folderLocation = kLoggerFilenameFolderLocation;
	
	return self;
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
	[logger initializeAmazonUploadProvider];
}

+ (void)addLogEvent:(NSString *)event {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	if (logger.loggingEnabled) {
		// only allow logging if enabled
		NSDate *date = [NSDate date];
		NSString *eventString = [logger eventString:event forDate:date];
		[logger writeLogEntry:eventString toFilename:[logger filenameForDate:date]];
		
		[logger truncateFilesBeyondRetentionForDate:date];
	}
}

+ (void)uploadAllFilesWithCompletion:(SLUploadCompletionHandler)completionHandler {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	if (![logger amazonCredentialsSetCorrectly]) {
		// prevent upload if credentials not set
		logger.uploadInProgress = NO; // reset upload in progress
		if (completionHandler) {
			completionHandler(NO, [NSError errorWithDomain:@"com.simplymadeapps.ios.simplelogger.aws.credentials.missing" code:999 userInfo:nil]);
		}
		return;
	}
	
	if (logger.uploadInProgress) {
		// prevent multiple uploads from kicking off
		if (completionHandler) {
			completionHandler(NO, nil);
		}
		return;
	}
	
	logger.uploadInProgress = YES;
	logger.uploadError = nil;
	logger.currentUploadCount = 0;
	
	NSArray *files = [logger logFiles];
	
	if (files) {
		logger.uploadTotal = files.count;
		
		for (NSString *file in files) {
			[logger uploadFilePathToAmazon:file withBlock:^(AWSTask * _Nonnull task) {
				logger.currentUploadCount = logger.currentUploadCount += 1;
				
				if (task.error) {
					NSLog(@"upload error: %@", task.error.localizedDescription);
					logger.uploadError = task.error;
				} else {
					// remove file after successful upload
					if (![logger filenameIsCurrentDay:file]) {
						[logger removeFile:file];
					}
				}
				
				if (logger.currentUploadCount == logger.uploadTotal) {
					// final upload complete
					logger.uploadInProgress = NO;
					
					if (completionHandler) {
						BOOL uploadSuccess = YES;
						if (logger.uploadError) {
							uploadSuccess = NO;
						}
						completionHandler(uploadSuccess, logger.uploadError);
					}
				}
			}];
		}
	} else {
		logger.uploadInProgress = NO;
		if (completionHandler) {
			completionHandler(NO, logger.uploadError);
		}
	}
}

+ (NSString *)logOutputForFileDate:(NSDate *)date {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	NSError *error;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	NSString *filePath = [docDirectory stringByAppendingPathComponent:[logger filenameForDate:date]];
	NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
	
	return contents;
}

+ (void)removeAllLogFiles {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	[logger removeAllLogFiles];
}

#pragma mark - Instance Methods
- (void)uploadFilePathToAmazon:(NSString *)filename withBlock:(SLAmazonTaskUploadCompletionHandler)block {
	AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
	[transferUtility uploadFile:[NSURL fileURLWithPath:[self fullFilePathForFilename:filename]] bucket:self.awsBucket key:[self bucketFileLocationForFilename:filename] contentType:@"text/plain" expression:nil completionHandler:^(AWSS3TransferUtilityUploadTask * _Nonnull task, NSError * _Nullable error) {
		block((AWSTask *)task);
	}];
}

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

- (void)removeFile:(NSString *)filename {
	NSString *filePath = [self fullFilePathForFilename:filename];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error;
	[manager removeItemAtPath:filePath error:&error];
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

- (BOOL)filenameIsCurrentDay:(NSString *)filename {
	NSString *todayFilename = [self filenameForDate:[NSDate date]];
	if ([todayFilename isEqualToString:filename]) {
		return YES;
	} else {
		return NO;
	}
}

#pragma mark - Private
- (void)writeLogEntry:(NSString *)log toFilename:(NSString *)filename {
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

- (void)initializeAmazonUploadProvider {
	AWSStaticCredentialsProvider *provider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:self.awsAccessToken secretKey:self.awsSecret];
	AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:provider];
	AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

- (NSString *)bucketFileLocationForFilename:(NSString *)filename {
	return [NSString stringWithFormat:@"%@/%@", self.folderLocation, filename];
}

- (NSString *)fullFilePathForFilename:(NSString *)filename {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = paths[0];
	return [docDirectory stringByAppendingPathComponent:filename];
}

#pragma mark - Helpers
- (NSString *)filenameForDate:(NSDate *)date {
	NSString *filename = [self.filenameFormatter stringFromDate:date];
	return [NSString stringWithFormat:@"%@.%@", filename, self.filenameExtension];
}

- (BOOL)amazonCredentialsSetCorrectly {
	BOOL credentialsSetOk = YES;
	
	if (!self.awsBucket) {
		credentialsSetOk = NO;
	}
	
	if (!self.awsAccessToken) {
		credentialsSetOk = NO;
	}
	
	if (!self.awsSecret) {
		credentialsSetOk = NO;
	}
	
	if (self.awsRegion == 0) {
		credentialsSetOk = NO;
	}
	
	return credentialsSetOk;
}

@end
