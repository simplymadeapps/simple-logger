//
//  LogDetailViewController.h
//  SimpleLogger
//
//  Created by Bill Burgess on 8/4/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogDetailViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextView *logDetailTextView;
@property (nonatomic, strong) NSString *filename;

@end
