//
//  GameDataUtils.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#ifndef MultiplayerTurnBasedGame_GameDataUtils_h
#define MultiplayerTurnBasedGame_GameDataUtils_h

#import "UserInfo.h"

static NSString* getOpponentName(NSDictionary *gameData) {
  NSArray *players = gameData[@"players"];
  NSString *opponentName;

  if ([[players objectAtIndex:0] isEqualToString:[UserInfo sharedUserInfo].username])
    opponentName = [players objectAtIndex:1];
  else
    opponentName = [players objectAtIndex:0];
  
  return opponentName;
}

static NSString* friendNameForUsername(NSString *username) {
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

#endif
