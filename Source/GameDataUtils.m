//
//  GameDataUtils.c
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 19/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameDataUtils.h"
#import "Constants.h"
#import "UserInfo.h"
#import <mgwuSDK/MGWU.h>

NSString* getOpponentName(NSDictionary *gameData) {
  NSArray *players = gameData[@"players"];
  NSString *opponentName;
  
  if (players) {
    
    if ([[players objectAtIndex:0] isEqualToString:[UserInfo sharedUserInfo].username])
      opponentName = [players objectAtIndex:1];
    else
      opponentName = [players objectAtIndex:0];
    
    return opponentName;
    
  } else {
    return gameData[@"opponent"];
  }
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

NSDictionary* getMatchById(NSNumber *matchID) {
  NSArray *games = [UserInfo sharedUserInfo].allGames;
  
  for (NSDictionary *game in games) {
    if ([game[@"gameid"] isEqualToNumber:matchID]) {
      return game;
    }
  }
  
  return nil;
}

void performMoveForPlayerInGame(NSString *move, NSString *playerName, NSDictionary* game, id target, SEL callback) {
  int nextMoveNumber = [game[@"movecount"] intValue];
  int gameID =  [game[@"gameid"] intValue];
  NSString *oponnentUserName = getOpponentName(game);
  NSString *playerUserName = [[UserInfo sharedUserInfo] username];
  NSString *newGameState = game[@"gamestate"];
  
  if (newGameState == nil) {
    newGameState = GAME_STATE_STARTED;
  }
  
  // After 6 rounds, mark game as completed
  if (nextMoveNumber > 6) {
    newGameState = GAME_STATE_COMPLETED;
  }
  
  // add a move to the game data
  NSMutableDictionary *gameData = game[@"gamedata"];
  
  if (!gameData) {
    gameData = [NSMutableDictionary dictionary];
  }
  
  // calculate current round (move 0 and 1 are part of round 1, move 2 and 3 are part of round 2, etc.)
  NSInteger currentRound = [game[@"movecount"] intValue] / 2;
  currentRound += 1;
  NSString *currentRoundString = [NSString stringWithFormat:@"%i",currentRound];
  
  NSMutableDictionary *currentRoundGameData = game[@"gamedata"][currentRoundString];
  
  if (!currentRoundGameData) {
    currentRoundGameData = [NSMutableDictionary dictionary];
    gameData[currentRoundString] = currentRoundGameData;
  }
  
  currentRoundGameData[playerUserName] = move;
  
  [MGWU move:@{@"selectedElement":move} withMoveNumber:nextMoveNumber forGame:gameID withGameState:newGameState withGameData:gameData againstPlayer:oponnentUserName withPushNotificationMessage:@"Round completed" withCallback:callback onTarget:target];
}

