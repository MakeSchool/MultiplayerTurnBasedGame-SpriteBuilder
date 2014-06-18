//
//  GuessScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 06/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameplayScene.h"
#import <mgwuSDK/MGWU.h>

@implementation GameplayScene

- (void)completeRound {
  [MGWU move:@{} withMoveNumber:0 forGame:0 withGameState:@"started" withGameData:@{} againstPlayer:self.game[@"opponent"] withPushNotificationMessage:@"Round completed" withCallback:@selector(moveCompleted:) onTarget:self];
}

- (void)moveCompleted:(NSMutableDictionary*)newGame {
  CCTransition *popTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3f];
  [[CCDirector sharedDirector] popToRootSceneWithTransition:popTransition];
}

@end
