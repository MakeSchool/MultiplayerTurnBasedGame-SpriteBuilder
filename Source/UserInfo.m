//
//  UserInfo.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "UserInfo.h"
#import <mgwuSDK/MGWU.h>

@interface UserInfo ()

@property (nonatomic, assign) SEL refreshCallback;
@property (nonatomic, weak) id refreshTarget;

@end

@implementation UserInfo

#pragma mark - Initializer

+ (instancetype)sharedUserInfo {
  static dispatch_once_t once;
  static id _sharedInstance = nil;
  
  dispatch_once(&once, ^{
    _sharedInstance = [[self alloc] init];
  });
  
  return _sharedInstance;
}

#pragma mark - Refreshing

- (void)refreshWithCallback:(SEL)callback onTarget:(id)target {
  self.refreshCallback = callback;
  self.refreshTarget = target;
  
  [MGWU getMyInfoWithCallback:@selector(refreshCompleted:) onTarget:self];
}

- (void)refreshCompleted:(NSDictionary *)userInfo {
  [self extractUserInformation:userInfo];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [self.refreshTarget performSelector:self.refreshCallback withObject:userInfo];
#pragma clang diagnostic pop
  
}

#pragma mark - Extract User Information

- (void)extractUserInformation:(NSDictionary *)userInfo {
  // name and username
  _name = userInfo[@"info"][@"name"];
  _username = userInfo[@"info"][@"username"];
  [self splitGames:userInfo];
  
  _friends = [NSMutableArray arrayWithArray:userInfo[@"friends"]];
#ifdef DEBUG
  // in debug mode add a test friend that always plays back immediately
  NSDictionary *botFriend = @{
    @"fbid" : [@(INT_MAX) stringValue],
    @"lastplayed" : @"1403140089",
    @"losses" : @(0),
    @"name" : @"mgwu bot friend",
    @"rankpoints" : @(0),
    @"username" : [@(746384398726503) stringValue],
    @"wins" : @(0),
    };
  
  [_friends addObject:botFriend];
#endif
}

- (void)splitGames:(NSDictionary *)userInfo {
  // divide games into: gamesWaitingOn, gamesYourTurn, gamesCompleted
  self.gamesCompleted = [[NSMutableArray alloc] init];
  self.gamesYourTurn = [[NSMutableArray alloc] init];
  self.gamesTheirTurn = [[NSMutableArray alloc] init];
  
  self.allGames = userInfo[@"games"];
		
	for (NSMutableDictionary *game in self.allGames)
	{
		NSString* gameState = [game objectForKey:@"gamestate"];
		NSString* turn = [game objectForKey:@"turn"];
		
		NSString* oppName;
		NSArray* gamers = [game objectForKey:@"players"];
		if ([[gamers objectAtIndex:0] isEqualToString:self.username])
			oppName = [gamers objectAtIndex:1];
		else
			oppName = [gamers objectAtIndex:0];
    
		if ([gameState isEqualToString:@"ended"])
		{
			[self.gamesCompleted addObject:game];
		}
		else if ([turn isEqualToString:self.username])
		{
			//Preventing cheating
			NSString *gameID = [NSString stringWithFormat:@"%@",[game objectForKey:@"gameid"]];
			NSMutableDictionary *savedGame = [NSMutableDictionary dictionaryWithDictionary:[MGWU objectForKey:gameID]];
			if ([savedGame isEqualToDictionary:@{}])
				savedGame = game;
			else
				[savedGame setObject:[game objectForKey:@"newmessages"] forKey:@"newmessages"];
			[self.gamesYourTurn addObject:savedGame];
		}
		else
		{
			[self.gamesTheirTurn addObject:game];
		}
	}
}

@end
