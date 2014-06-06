//
//  PreMatchScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 06/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PreMatchScene.h"

@implementation PreMatchScene

- (void)startGame {
  CCScene *guessScene = [CCBReader loadAsScene:@"GuessScene"];
  [[CCDirector sharedDirector] pushScene:guessScene];
}

@end
