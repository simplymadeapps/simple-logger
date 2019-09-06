//
//  FileManager.m
//  SimpleLogger
//
//  Created by Bill Burgess on 9/6/19.
//  Copyright © 2019 Simply Made Apps Inc. All rights reserved.
//

#import "FileManager.h"

@implementation FileManager

+ (NSString *)fullFilePathForFilename:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    return [docDirectory stringByAppendingPathComponent:filename];
}

+ (void)writeLogEntry:(NSString *)log toFilename:(NSString *)filename {
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

@end
