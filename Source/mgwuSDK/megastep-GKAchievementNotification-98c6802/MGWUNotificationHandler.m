//
//  MGWUNotificationHandler.m
//
//  Created by Benjamin Borowski on 9/30/10.
//  Copyright 2010 Typeoneerror Studios. All rights reserved.
//  $Id$
//

#import <GameKit/GameKit.h>
#import <Availability.h>
#import "MGWUNotificationHandler.h"
#import "MGWUNotification.h"

static MGWUNotificationHandler *defaultHandler = nil;

#pragma mark -

@interface MGWUNotificationHandler(private)

- (void)displayNotification:(MGWUNotification *)notification;

@end

#pragma mark -

@implementation MGWUNotificationHandler(private)

- (void)displayNotification:(MGWUNotification *)notification
{
	[_topView addSubview:notification];
	[notification animateIn];
}

@end

#pragma mark -

@implementation MGWUNotificationHandler

#pragma mark -

+ (MGWUNotificationHandler *)defaultHandler
{
    if (!defaultHandler) defaultHandler = [[self alloc] init];
    return defaultHandler;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _topView = [[UIApplication sharedApplication] keyWindow];
        _queue = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

//- (void)dealloc
//{
//    [_queue release];
//    [super dealloc];
//}

#pragma mark -

- (void)notifyAchievementTitle:(NSString *)title andMessage:(NSString *)message
{
    [self notifyAchievementTitle:title message:message andImage:[UIImage imageNamed:@"gk-icon.png"]];
}

- (void)notifyAchievementTitle:(NSString *)title message:(NSString *)message andImage:(UIImage *)image;
{
	_topView = [[UIApplication sharedApplication] keyWindow];

    MGWUNotification *notification = [[MGWUNotification alloc] initWithTitle:title andMessage:message];
        notification.frame = [notification startFrame];
        notification.handlerDelegate = self;
        [notification setImage:image];
    
    [_queue addObject:notification];
    if ([_queue count] == 1)
    {
        [self displayNotification:notification];
    }
}

#pragma mark -
#pragma mark MGWUNotificationHandlerDelegate implementation

- (void)didHideAchievementNotification:(MGWUNotification *)notification
{
    [_queue removeObjectAtIndex:0];
    if ([_queue count])
    {
        [self displayNotification:(MGWUNotification *)[_queue objectAtIndex:0]];
    }
}

@end
