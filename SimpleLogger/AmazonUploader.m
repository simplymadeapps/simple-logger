//
//  AmazonUploader.m
//  SimpleLogger
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "AmazonUploader.h"
#import "SimpleLogger.h"
#import "FileManager.h"

@implementation AmazonUploader

+ (BOOL)amazonCredentialsSetCorrectly {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    BOOL credentialsSetOk = YES;
    
    if (!logger.awsBucket) {
        credentialsSetOk = NO;
    }
    
    if (!logger.awsAccessToken) {
        credentialsSetOk = NO;
    }
    
    if (!logger.awsSecret) {
        credentialsSetOk = NO;
    }
    
    if (logger.awsRegion == 0) {
        credentialsSetOk = NO;
    }
    
    return credentialsSetOk;
}

+ (void)initializeAmazonUploadProvider {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    AWSStaticCredentialsProvider *provider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:logger.awsAccessToken secretKey:logger.awsSecret];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:provider];
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
}

+ (NSString *)bucketFileLocationForFilename:(NSString *)filename {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    return [NSString stringWithFormat:@"%@/%@", logger.folderLocation, filename];
}

+ (void)uploadFilePathToAmazon:(NSString *)filename withBlock:(SLAmazonTaskUploadCompletionHandler)block {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    [transferUtility uploadFile:[NSURL fileURLWithPath:[FileManager fullFilePathForFilename:filename]] bucket:logger.awsBucket key:[AmazonUploader bucketFileLocationForFilename:filename] contentType:@"text/plain" expression:nil completionHandler:^(AWSS3TransferUtilityUploadTask * _Nonnull task, NSError * _Nullable error) {
        block((AWSTask *)task);
    }];
}

@end
