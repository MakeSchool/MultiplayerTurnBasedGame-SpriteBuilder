//
//  MGWUNotificationHandler.h
//
//  Created by Benjamin Borowski on 9/30/10.
//  Copyright 2010 Typeoneerror Studios. All rights reserved.
//  $Id$
//

#import <Foundation/Foundation.h>
#import "MGWUNotification.h"

/**
 * Game Center has a notification window that slides down and informs the GKLocalPlayer 
 * that they've been authenticated. The MGWUNotification classes are a way to 
 * display achievements awarded to the player in the same manner; more similar to Xbox Live 
 * style achievement popups. The achievement dialogs are added to the UIWindow view of your application.
 *
 * The MGWUNotificationHandler is a singleton pattern that you can use to 
 * notify the user anywhere in your application that they earned an achievement.
 */
@interface MGWUNotificationHandler : NSObject <MGWUNotificationHandlerDelegate>
{
    UIView         *_topView;  /**< Reference to top view of UIApplication. */
    NSMutableArray *_queue;    /**< Queue of achievement notifiers to display. */
}

/**
 * Returns a reference to the singleton MGWUNotificationHandler.
 * @return a single MGWUNotificationHandler.
 */
+ (MGWUNotificationHandler *)defaultHandler;

/**
 * Show an achievement notification with a message manually added.
 * @param title    The title of the achievement.
 * @param message  Description of the achievement.
 */
- (void)notifyAchievementTitle:(NSString *)title andMessage:(NSString *)message;

/**
 * Show an achievement notification with a message manually added.
 * @param title    The title of the achievement.
 * @param message  Description of the achievement.
 # @param image    Image to display along the description. 
 */

- (void)notifyAchievementTitle:(NSString *)title message:(NSString *)message andImage:(UIImage *)image;

@end
