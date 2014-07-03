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
  performMoveForPlayerInGame(_selectedElement, [[UserInfo sharedUserInfo] username], self.game, self, @selector(moveCompleted:));
}

- (void)moveCompleted:(NSMutableDictionary*)newGame {
  if ([getOpponentName(self.game) isEqualToString:BOT_USERNAME]) {
    CCLOG(@"Playing against Bot");
  }
  
  CCTransition *popTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3f];
  [[CCDirector sharedDirector] popToRootSceneWithTransition:popTransition];
}

@end
