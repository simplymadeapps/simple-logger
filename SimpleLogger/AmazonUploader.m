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
    
    [self removePreviousTransferUtilityForKey:logger.awsConfigurationKey];
    
    // generate a new configuration key for uploads
    logger.awsConfigurationKey = [self configKey];
    
    AWSStaticCredentialsProvider *provider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:logger.awsAccessToken secretKey:logger.awsSecret];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:logger.awsRegion credentialsProvider:provider];
    [AWSS3TransferUtility registerS3TransferUtilityWithConfiguration:configuration forKey:logger.awsConfigurationKey];
}

+ (NSString *)configKey {
    return [NSString stringWithFormat:@"SimpleLogger.AWS.ConfigKey.%@",[NSUUID UUID].UUIDString];
}

+ (void)removePreviousTransferUtilityForKey:(NSString *)key {
    if (key) {
        // we have a previously initialized configuration
        // delete old configuration to save on memory
        [AWSS3TransferUtility removeS3TransferUtilityForKey:key];
    }
}

+ (NSString *)bucketFileLocationForFilename:(NSString *)filename {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    return [NSString stringWithFormat:@"%@/%@", logger.folderLocation, filename];
}

+ (void)uploadFile:(NSString *)file completionHandler:(SLUploadCompletionHandler)completionHandler {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    [AmazonUploader uploadFilePathToAmazon:file withBlock:^(AWSTask * _Nonnull task) {
        logger.currentUploadCount++;
        
        if (task.error) {
            logger.uploadError = task.error;
        }
        
        if (!task.error && ![FileManager filenameIsCurrentDay:file]) {
            // remove file on success upload
            [FileManager removeFile:file];
        }
        
        if (logger.currentUploadCount == logger.uploadTotal) {
            // final upload complete
            logger.uploadInProgress = NO;
            completionHandler(logger.uploadError == nil, logger.uploadError);
        }
    }];
}

+ (void)uploadFilePathToAmazon:(NSString *)filename withBlock:(SLAmazonTaskUploadCompletionHandler)block {
    SimpleLogger *logger = [SimpleLogger sharedLogger];
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility S3TransferUtilityForKey:logger.awsConfigurationKey];
    [transferUtility uploadFile:[NSURL fileURLWithPath:[FileManager fullFilePathForFilename:filename]] bucket:logger.awsBucket key:[AmazonUploader bucketFileLocationForFilename:filename] contentType:@"text/plain" expression:nil completionHandler:^(AWSS3TransferUtilityUploadTask * _Nonnull task, NSError * _Nullable error) {
        block((AWSTask *)task);
    }];
}

@end
