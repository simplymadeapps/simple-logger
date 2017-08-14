//
//  AppDelegate.m
//  SimpleLogger
//
//  Created by Bill Burgess on 7/25/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "SimpleLogger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	[SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"simpleinout-staging" accessToken:@"AKIAJONJU2KMX5L2GKPQ" secret:@"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"];
	
	[[SimpleLogger sharedLogger] setFolderLocation:@"app-logs/211/simpleinout-ios"];
	
	return YES;
}

@end
