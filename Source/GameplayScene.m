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
  _selectedElement = CHOICE_SCISSORS;
  [self completeRound];
}

- (void)completeRoundWithRock {
  _selectedElement = CHOICE_ROCK;
  [self completeRound];
}

- (void)completeRoundWithPaper {
  _selectedElement = CHOICE_PAPER;
  [self completeRound];
}

- (void)completeRound {
  performMoveForPlayerInGame(_selectedElement, [[UserInfo sharedUserInfo] username], self.game, self, @selector(moveCompleted:));
}

- (void)moveCompleted:(NSMutableDictionary*)newGame {
  if (isCurrentRoundCompleted(newGame)) {
    // if the current round is completed with this move, we need to present the result scene
    [self presentResultScene:newGame];
  } else {
    // if this round is not completed, we return to the main scene and wait until other player finishes round before presenting results
    [self backToMainScene];
  }
}

- (void)botCompleted:(NSMutableDictionary*)newGame {
  CCTransition *popTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3f];
  [[CCDirector sharedDirector] popToRootSceneWithTransition:popTransition];
}

#pragma mark - Transition after move was performed

- (void)backToMainScene {
  if ([getOpponentName(self.game) isEqualToString:BOT_USERNAME]) {
    CCLOG(@"Playing against Bot");
  } else {
    CCTransition *popTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3f];
    [[CCDirector sharedDirector] popToRootSceneWithTransition:popTransition];
  }
}

- (void)presentResultScene:(NSDictionary *)game {
  CCScene *gameResultScene = [CCBReader loadAsScene:@"RoundResultScene"];
  [gameResultScene.children[0] setGame:self.game];
  
  CCTransition *pushTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionLeft duration:0.3f];
  [[CCDirector sharedDirector] pushScene:gameResultScene withTransition:pushTransition];
}

@end
