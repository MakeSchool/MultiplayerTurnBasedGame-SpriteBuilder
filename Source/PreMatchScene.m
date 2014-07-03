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
#import "GameDataUtils.h"

@implementation PreMatchScene {
  CCLabelTTF *_playerNameLabel;
  CCLabelTTF *_opponentNameLabel;
  CCLabelTTF *_currentRound;
  
  // labels
  CCLabelTTF *_playerRound1;
  CCLabelTTF *_playerRound2;
  CCLabelTTF *_playerRound3;
  
  CCLabelTTF *_opponentRound1;
  CCLabelTTF *_opponentRound2;
  CCLabelTTF *_opponentRound3;
}

- (void)onEnter {
  [super onEnter];
  
  NSAssert(self.game != nil, @"Game object needs to be assigned before prematch scene is displayed");
  
  _playerNameLabel.string = [UserInfo sharedUserInfo].name;
  _opponentNameLabel.string = friendNameForUsername(getOpponentName(self.game));
  _currentRound.string = [self.game[@"movecount"] stringValue] ? [self.game[@"movecount"] stringValue] : @"1";
  
  [self fillRoundLabels];
}

- (void)startGame {
  CCScene *guessScene = [CCBReader loadAsScene:@"GameplayScene"];
  
  GameplayScene *gameplayScene = guessScene.children[0];
  gameplayScene.game = self.game;
  
  [[CCDirector sharedDirector] pushScene:guessScene];
}

- (void)backButtonPressed {
  [[CCDirector sharedDirector] popScene];
}

#pragma mark - Fill User Interface

- (void)fillRoundLabels {
  NSDictionary *round1 = self.game[@"gamedata"][@"1"];
  NSDictionary *round2 = self.game[@"gamedata"][@"2"];
  NSDictionary *round3 = self.game[@"gamedata"][@"3"];
  
  NSString *playerUsername = [[UserInfo sharedUserInfo] username];
  NSString *opponentUsername = getOpponentName(self.game);
  
  NSString *playerMoveRound1 = round1[playerUsername];
  NSString *opponentMoveRound1 = round1[opponentUsername];
  
  NSString *playerMoveRound2 = round2[playerUsername];
  NSString *opponentMoveRound2 = round2[opponentUsername];
  
  NSString *playerMoveRound3 = round3[playerUsername];
  NSString *opponentMoveRound3 = round3[opponentUsername];
}

@end
