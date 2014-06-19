//
//  GameDataUtils.c
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 19/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameDataUtils.h"

#import "UserInfo.h"

NSString* getOpponentName(NSDictionary *gameData) {
  NSArray *players = gameData[@"players"];
  NSString *opponentName;
  
  if ([[players objectAtIndex:0] isEqualToString:[UserInfo sharedUserInfo].username])
    opponentName = [players objectAtIndex:1];
  else
    opponentName = [players objectAtIndex:0];
  
  return opponentName;
}

NSString* friendNameForUsername(NSString *username) {
  for (NSMutableDictionary *friend in [UserInfo sharedUserInfo].friends)
  {
    //Add friendName to game if you're friends
    if ([[friend objectForKey:@"username"] isEqualToString:username])
    {
      return [friend objectForKey:@"name"];
    }
  }
  
  return @"Random Player";
}

NSNumber* doesPlayerHaveMatchWithFriend(NSString *username) {
  NSArray *games = [UserInfo sharedUserInfo].allGames;
  
  for (NSDictionary *game in games) {
    for (NSString *playerID in  game[@"players"]) {
      if ([playerID isEqualToString:username]) {
        return game[@"gameid"];
      }
    }
  }
  
  return nil;
}
