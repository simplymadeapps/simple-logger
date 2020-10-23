//
//  LogDetailViewController.m
//  SimpleLogger
//
//  Created by Bill Burgess on 8/4/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "LogDetailViewController.h"
#import "SimpleLogger.h"

@interface LogDetailViewController ()

@end

@implementation LogDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirectory = paths[0];
    NSString *filePath = [docDirectory stringByAppendingPathComponent:self.filename];
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    self.logDetailTextView.text = contents;
    
    UIBarButtonItem *upload = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStylePlain target:self action:@selector(uploadFirstFileInStack:)];
    self.navigationItem.rightBarButtonItem = upload;
}

- (void)uploadFirstFileInStack:(id)sender {
    [SimpleLogger uploadAllFilesWithCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];
}

@end
