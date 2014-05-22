//
//  MGWUNotification.h
//
//  Created by Benjamin Borowski on 9/30/10.
//  Copyright 2010 Typeoneerror Studios. All rights reserved.
//  $Id$
//

#import <UIKit/UIKit.h>

@class MGWUNotification;

#define kGKAchievementAnimeTime     0.4f
#define kGKAchievementDisplayTime   1.75f

#define kGKAchievementBarWidthRatioPhone 0.88f
#define kGKAchievementBarWidthRatioPad   0.60f

#define kGKAchievementFrameHeight   52.0f
#define kGKAchievementTextHeight    22.0f
#define kGKAchievementImageSize     34.0f

#define kGKAchievementMoveOffset    (kGKAchievementFrameHeight + 11.0f)

#pragma mark -

/**
 * The handler delegate responds to hiding and showing
 * of the game center notifications.
 */
@protocol MGWUNotificationHandlerDelegate <NSObject>

@optional

/**
 * Called on delegate when notification is hidden.
 * @param nofification  The notification view that was hidden.
 */
- (void)didHideAchievementNotification:(MGWUNotification *)notification;

/**
 * Called on delegate when notification is shown.
 * @param nofification  The notification view that was shown.
 */
- (void)didShowAchievementNotification:(MGWUNotification *)notification;

/**
 * Called on delegate when notification is about to be hidden.
 * @param nofification  The notification view that will be hidden.
 */
- (void)willHideAchievementNotification:(MGWUNotification *)notification;

/**
 * Called on delegate when notification is about to be shown.
 * @param nofification  The notification view that will be shown.
 */
- (void)willShowAchievementNotification:(MGWUNotification *)notification;

@end

#pragma mark -

/**
 * The MGWUNotification is a view for showing the achievement earned.
 */
@interface MGWUNotification : UIView
{
    NSString *_message;  /**< Optional custom achievement message. */
    NSString *_title;    /**< Optional custom achievement title. */

    UIImageView  *_background;  /**< Stretchable background view. */
    UIImageView  *_logo;        /**< Logo that is displayed on the left. */

    UILabel      *_textLabel;    /**< Text label used to display achievement title. */
    UILabel      *_detailLabel;  /**< Text label used to display achievement description. */

    CGFloat _barWidthRatio; /**< What percentage of the width of the status bar we use for the notification. */
    
    id<MGWUNotificationHandlerDelegate> _handlerDelegate;  /**< Reference to nofification handler. */
}

/** Optional custom achievement message. */
@property (nonatomic, retain) NSString *message;
/** Optional custom achievement title. */
@property (nonatomic, retain) NSString *title;
/** Stretchable background view. */
@property (nonatomic, retain) UIImageView *background;
/** Logo that is displayed on the left. */
@property (nonatomic, retain) UIImageView *logo;
/** Text label used to display achievement title. */
@property (nonatomic, retain) UILabel *textLabel;
/** Text label used to display achievement description. */
@property (nonatomic, retain) UILabel *detailLabel;
/** Reference to nofification handler. */
@property (nonatomic, retain) id<MGWUNotificationHandlerDelegate> handlerDelegate;

#pragma mark -

/**
 * Create a notification with a custom title and description.
 * @param title    Title to display in notification.
 * @param message  Descriotion to display in notification.
 * @return a GKAchievementNoficiation view.
 */
- (id)initWithTitle:(NSString *)title andMessage:(NSString *)message;

/**
 * Show the notification.
 */
- (void)animateIn;

/**
 * Hide the notification.
 */
- (void)animateOut;

/**
 * Change the logo that appears on the left.
 * @param image  The image to display.
 */
- (void)setImage:(UIImage *)image;

#pragma mark - Compute the geometry of the notification

/*
 * The size of the rectangle holding the notification, depending on device.
 */
- (CGRect)defaultSize;

/**
 * Compute the frame at the start of animations, taking into account device and orientation.
 */
- (CGRect)startFrame;

/*
 * Compute the frame at the end of animations.
 */
- (CGRect)endFrame;

@end
