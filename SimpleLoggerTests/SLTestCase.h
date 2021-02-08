//
//  SLTestCase.h
//  SimpleLogger
//
//  Created by Bill Burgess on 8/7/17.
//  Copyright © 2017 Simply Made Apps Inc. All rights reserved.
//

#import "SimpleLogger.h"
#import <KIF/KIF.h>
#import <OCMock/OCMock.h>

@interface SLTestCase : KIFTestCase
- (NSDate *)testDate;
- (void)saveDummyFiles:(NSInteger)count;
- (void)saveRegularFiles:(NSInteger)count;
- (void)deleteRegularFiles;
- (void)verifyAndStopMocking:(id)mock;
@end

@interface SimpleLogger (UnitTests)
- (NSString *)eventString:(NSString *)string forDate:(NSDate *)date;
@end
