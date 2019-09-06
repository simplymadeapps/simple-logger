//
//  AmazonUploader.h
//  SimpleLogger
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

typedef void(^SLAmazonTaskUploadCompletionHandler)(AWSTask *task);

@interface AmazonUploader : NSObject

+ (BOOL)amazonCredentialsSetCorrectly;
+ (void)initializeAmazonUploadProvider;
+ (NSString *)bucketFileLocationForFilename:(NSString *)filename;
+ (void)uploadFilePathToAmazon:(NSString *)filename withBlock:(SLAmazonTaskUploadCompletionHandler)block;

@end
