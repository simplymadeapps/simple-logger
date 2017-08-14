//
//  NSDate+SIO.h
//
//  Created by Bill Burgess on 5/12/17.
//  Copyright © 2017 Simply Made Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (SMA)

- (NSDate *)dateByAddingDays:(NSInteger)days;
- (NSDate *)dateBySubtractingDays:(NSInteger)days;

- (NSDate *)minTime;
- (NSDate *)maxTime;

- (BOOL)isLaterThanDate:(NSDate *)date;
- (BOOL)isEarlierThanDate:(NSDate *)date;
- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate;


@end
