//
//  GuessScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 06/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameplayScene.h"

@implementation GameplayScene

- (void)completeRound {
  CCTransition *popTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:0.3f];
  [[CCDirector sharedDirector] popToRootSceneWithTransition:popTransition];
}

@end
