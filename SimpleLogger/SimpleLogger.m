//
//  SimpleLogger.m
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SimpleLogger.h"
#import "NSDate+SMA.h"

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
	if (self = [super init]) {
		self.retentionDays = kLoggerRetentionDaysDefault;
		self.logFormatter = [[NSDateFormatter alloc] init];
		self.logFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
		self.filenameFormatter = [[NSDateFormatter alloc] init];
		self.filenameFormatter.dateFormat = kLoggerFilenameDateFormat;
		self.filenameExtension = kLoggerFilenameExtension;
	}
	return self;
}

+ (void)initWithAWSRegion:(NSString *)region bucket:(NSString *)bucket accessToken:(NSString *)accessToken secret:(NSString *)secret {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	logger.awsRegion = region;
	logger.awsBucket = bucket;
	logger.awsAccessToken = accessToken;
	logger.awsSecret = secret;
}

+ (void)logEvent:(NSString *)event {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	NSDate *date = [NSDate date];
	NSString *eventString = [logger eventString:event forDate:date];
	[logger writeLogEntry:eventString toFilename:[logger filenameForDate:date]];
	
	[logger truncateFilesBeyondRetentionForDate:date];
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
	NSArray *contents = [manager contentsOfDirectoryAtPath:docDirectory error:nil];
	
	for (NSString *file in contents) {
		if ([[file pathExtension] isEqualToString:self.filenameExtension]) {
			NSError *error;
			NSString *path = [docDirectory stringByAppendingPathComponent:file];
			[manager removeItemAtPath:path error:&error];
		}
	}
}

- (NSString *)eventString:(NSString *)string forDate:(NSDate *)date {
	NSString *dateString = [self.logFormatter stringFromDate:date];
	return [NSString stringWithFormat:@"[%@] %@", dateString, string];
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
	
	NSError *error;
	NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirectory error:&error];
	
	NSDate *retainDate = [self lastRetentionDateForDate:date];
	
	for (NSString *file in content) {
		NSLog(@"filename: %@", file);
		NSDate *fileDate = [self.logFormatter dateFromString:file];
		NSLog(@"date from File: %@", fileDate);
		if ([[file pathExtension] isEqualToString:self.filenameExtension]) { // only truncate matching file types
			if (![fileDate isBetweenDate:retainDate andDate:date]) {
				// file is outside our retention period, delete file
				NSError *error;
				NSString *path = [docDirectory stringByAppendingPathComponent:file];
				[[NSFileManager defaultManager] removeItemAtPath:path error:&error];
			}
		}
	}
}

- (NSDate *)lastRetentionDateForDate:(NSDate *)date {
	return [date dateBySubtractingDays:self.retentionDays];
}

#pragma mark - Helpers
- (NSString *)filenameForDate:(NSDate *)date {
	NSString *filename = [self.filenameFormatter stringFromDate:date];
	return [NSString stringWithFormat:@"%@.%@", filename, self.filenameExtension];
}

@end
