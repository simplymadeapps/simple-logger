//
//  SimpleLogger.m
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SimpleLogger.h"

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

+ (void)logEvent:(NSString *)event withParameters:(NSDictionary *)parameters {
	SimpleLogger *logger = [SimpleLogger sharedLogger];
	
	// TODO: Build log entry
	
	
	
	[logger writeLogEntry:event toFilename:[logger filenameForDate:[NSDate date]]];
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

// get all files
// https://stackoverflow.com/questions/8376511/list-saved-files-in-ios-documents-directory-in-a-uitableview

#pragma mark - Helpers
- (NSString *)filenameForDate:(NSDate *)date {
	NSString *filename = [self.filenameFormatter stringFromDate:date];
	return [NSString stringWithFormat:@"%@.%@", filename, self.filenameExtension];
}

@end
