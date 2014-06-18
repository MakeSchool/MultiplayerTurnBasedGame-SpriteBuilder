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

static NSString* getOpponentName(NSDictionary* gameData) {
  NSArray *players = gameData[@"players"];
  NSString *opponentName;

  if ([[players objectAtIndex:0] isEqualToString:[UserInfo sharedUserInfo].username])
    opponentName = [players objectAtIndex:1];
  else
    opponentName = [players objectAtIndex:0];
  
  return opponentName;
}

#endif
