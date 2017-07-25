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
		
	}
	return self;
}

@end
