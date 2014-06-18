//
//  PreMatchScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 06/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PreMatchScene.h"
#import <mgwuSDK/MGWU.h>
#import "UserInfo.h"

@implementation PreMatchScene {
  CCLabelTTF *_playerNameLabel;
  CCLabelTTF *_opponentNameLabel;
}

- (void)startGame {
  CCScene *guessScene = [CCBReader loadAsScene:@"GameplayScene"];
  
  GameplayScene *gameplayScene = guessScene.children[0];
  gameplayScene.game = self.game;
  
  [[CCDirector sharedDirector] pushScene:guessScene];
}

- (void)onEnter {
  [super onEnter];
  
  NSAssert(self.game != nil, @"Game object needs to be assigned before prematch scene is displayed");
  
  _playerNameLabel.string = [UserInfo sharedUserInfo].name;
  _opponentNameLabel.string = self.game[@"opponent"];
}

@end
