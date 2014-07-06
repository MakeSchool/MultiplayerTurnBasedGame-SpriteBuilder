//
//  UserInfo.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 The User Info class stores all of the information received from the MGWU server.
 UserInfo is implemented as a singleton. If you want to access information do it as follows:
 @code
 // access username
 [[UserInfo sharedUserInfo] username];
 @endcode
 If you want to update the user info you should call:
 @code
 [[UserInfo sharedUserInfo] refreshWithCallback:onTarget:];
 @endcode
*/

@interface UserInfo : NSObject

/**
 Full name of the current user.
 */
@property (nonatomic, copy, readonly) NSString *name;
/**
 Facebook username of the current user.
 */
@property (nonatomic, copy, readonly) NSString *username;
/**
 Games where current player is waiting on move by other player.
 */
@property (nonatomic, strong) NSMutableArray *gamesTheirTurn;
/**
 Games where it's the current players turn.
 */
@property (nonatomic, strong) NSMutableArray *gamesYourTurn;
/**
 Completed games.
 */
@property (nonatomic, strong) NSMutableArray *gamesCompleted;
/**
 List of all games.
 */
@property (nonatomic, strong) NSMutableArray *allGames;
/**
 List of facebook friends
 */
@property (nonatomic, strong) NSMutableArray *friends;

/**
 Access to UserInfo singleton
 */
+ (instancetype)sharedUserInfo;

/** 
 Download latest information from server and update UserInfo with the latest data.
 After successful download this method calls the provided callback on the provided target
 */
- (void)refreshWithCallback:(SEL)callback onTarget:(id)target;

@end