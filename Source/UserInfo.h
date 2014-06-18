//
//  UserInfo.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfo : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *username;
@property (nonatomic, strong) NSMutableArray *gamesTheirTurn;
@property (nonatomic, strong) NSMutableArray *gamesYourTurn;
@property (nonatomic, strong) NSMutableArray *gamesCompleted;
@property (nonatomic, strong) NSMutableArray *allGames;

+ (instancetype)sharedUserInfo;

- (void)refreshWithCallback:(SEL)callback onTarget:(id)target;

@end