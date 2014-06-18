//
//  Rainbow.m
//  mgwuSDK
//
//  Created by Ashutosh Desai on 8/19/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "MGWURainbow.h"

@implementation MGWURainbow

MGWURainbow *rainbow;

+ (NSString*)stuff
{
	return @"keg";
}

- (NSString*)otherStuff:(NSString*)stuff
{
	return [[@"m" stringByAppendingString:stuff] stringByAppendingString:@"ameswi"];
}

+ (NSString*)someMoreStuff
{
	return @"";
}

+(NSString*)rainbows
{
	if (!rainbow)
		rainbow = [[MGWURainbow alloc] init];
	
	NSString* a = @"a";
	a = [a stringByAppendingFormat:@"%@", [MGWURainbow stuff]];
	a = [rainbow otherStuff:a];
	a = [a stringByAppendingString:[MGWURainbow someMoreStuff]];
	a = [a stringByAppendingString:@"thus!"];
	
	return a;
}

@end
