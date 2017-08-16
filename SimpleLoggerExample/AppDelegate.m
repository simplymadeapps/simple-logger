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
	
	[SimpleLogger initWithAWSRegion:AWSRegionUSEast1 bucket:@"test-bucket" accessToken:@"test-token" secret:@"test-secret"];
	
	[[SimpleLogger sharedLogger] setFolderLocation:@"mytestfolder/userlogs"];
	
	return YES;
}

@end
