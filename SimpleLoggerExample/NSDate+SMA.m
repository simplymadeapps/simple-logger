//
//  NSDate+SIO.m
//
//  Created by Bill Burgess on 5/12/17.
//  Copyright © 2017 Simply Made Apps. All rights reserved.
//

#import "NSDate+SMA.h"

@implementation NSDate (SMA)

- (NSDate *)dateByAddingDays:(NSInteger)days {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setDay:days];
	
	return [calendar dateByAddingComponents:components toDate:self options:0];
}

- (NSDate *)dateBySubtractingDays:(NSInteger)days {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setDay:-1*days];
	
	return [calendar dateByAddingComponents:components toDate:self options:0];
}

- (BOOL)isLaterThanDate:(NSDate *)date {
	return ([self compare:date] == NSOrderedDescending);
}

- (BOOL)isEarlierThanDate:(NSDate *)date {
	return ([self compare:date] == NSOrderedAscending);
}

- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate {
	return !([self compare:beginDate] == NSOrderedAscending || [self compare:endDate] == NSOrderedDescending);
}

@end
