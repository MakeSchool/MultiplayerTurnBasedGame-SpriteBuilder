//
//  GuessScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 06/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameplayScene.h"
#import "GameDataUtils.h"
#import "Constants.h"
#import <mgwuSDK/MGWU.h>
#import "UserInfo.h"

@implementation GameplayScene {
  NSString *_selectedElement;
}

- (void)completeRoundWithScissors {
  _selectedElement = @"Scissors";
  [self completeRound];
}

- (void)completeRoundWithRock {
  _selectedElement = @"Rock";
  [self completeRound];
}

- (void)completeRoundWithPaper {
  _selectedElement = @"Paper";
  [self completeRound];
}

- (void)completeRound {
  int nextMoveNumber = [self.game[@"movecount"] intValue];
  int gameID =  [self.game[@"gameid"] intValue];
  NSString *oponnentUserName = getOpponentName(self.game);
  NSString *playerUserName = [[UserInfo sharedUserInfo] name];
  NSString *newGameState = self.game[@"gamestate"];
  
  // After 6 rounds, mark game as completed
  if (nextMoveNumber > 6) {
    newGameState = GAME_STATE_COMPLETED;
  } else {
    newGameState = GAME_STATE_IN_PROGRESS;
  }
  
  // add a move to the game data
  NSMutableDictionary *gameData = self.game[@"gamedata"];
  
  if (!gameData) {
    gameData = [NSMutableDictionary dictionary];
  }
  
  // calculate current round (move 0 and 1 are part of round 1, move 2 and 3 are part of round 2, etc.)
  NSInteger currentRound = [self.game[@"movecount"] intValue] / 2;
  currentRound += 1;
  NSString *currentRoundString = [NSString stringWithFormat:@"%i",currentRound];
  
  NSMutableDictionary *currentRoundGameData = self.game[@"gamedata"][currentRoundString];
  
  if (!currentRoundGameData) {
    currentRoundGameData = [NSMutableDictionary dictionary];
    gameData[currentRoundString] = currentRoundGameData;
  }
  
  currentRoundGameData[playerUserName] = _selectedElement;
  
  [MGWU move:@{@"selectedElement":_selectedElement} withMoveNumber:nextMoveNumber forGame:gameID withGameState:newGameState withGameData:@{} againstPlayer:oponnentUserName withPushNotificationMessage:@"Round completed" withCallback:@selector(moveCompleted:) onTarget:self];
}

- (void)moveCompleted:(NSMutableDictionary*)newGame {
  CCTransition *popTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3f];
  [[CCDirector sharedDirector] popToRootSceneWithTransition:popTransition];
}

@end
