//
//  RoundResultScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "RoundResultScene.h"
#import "GameDataUtils.h"
#import "UserInfo.h"
#import "UserInterfaceUtils.h"
#import "PreMatchScene.h"

NSString * const YOU_WIN = @"You win this round!";
NSString * const YOU_LOSE = @"You lose this round!";
NSString * const DRAW = @"It's a draw!";

@implementation RoundResultScene {
  CCSprite *_playerChoiceSprite;
  CCSprite *_opponentChoiceSprite;
  CCLabelTTF *_roundResultLabel;
  CCLabelTTF *_roundCaptionLabel;
}

- (void)onEnter {
  [super onEnter];
  
  NSAssert(self.game != nil, @"Game object needs to be assigned before prematch scene is displayed");
  
  // we want to display results of last round
  NSInteger currentRound = currentRoundInGame(self.game) - 1;
  NSString *currentRoundString = [NSString stringWithFormat:@"%d", currentRound];
  NSDictionary *currentRoundData = self.game[@"gamedata"][currentRoundString];
  
  _roundCaptionLabel.string = [NSString stringWithFormat:@"Round %d:", currentRound];
  
  NSString *playerUsername = [[UserInfo sharedUserInfo] username];
  NSString *opponentUsername = getOpponentName(self.game);
  
  NSString *playerMove = currentRoundData[playerUsername];
  NSString *opponentMove = currentRoundData[opponentUsername];
  
  _playerChoiceSprite.spriteFrame = spriteFrameForChoice(playerMove);
  _opponentChoiceSprite.spriteFrame = spriteFrameForChoice(opponentMove);
  
  NSInteger winner = calculateWinnerOfRound(playerMove, opponentMove);
  
  if (winner == 0) {
    _roundResultLabel.string = DRAW;
  } else if (winner == -1) {
    _roundResultLabel.string = YOU_WIN;
  } else if (winner == 1) {
    _roundResultLabel.string = YOU_LOSE;
  }
}

- (void)okButtonPressed {
  if (self.nextScene == RoundResultSceneNextSceneMainScene) {
    [[CCDirector sharedDirector] popToRootScene];
  } else if (self.nextScene == RoundResultSceneNextScenePreMatchScene) {
    CCScene *scene = [CCBReader loadAsScene:@"PreMatchScene"];
    PreMatchScene *prematchScene = scene.children[0];
    prematchScene.game = self.game;
    [[CCDirector sharedDirector] presentScene:scene];
  } else {
    NSAssert(NO, @"You need to choose a valid 'nextScene' for RoundResultScene");
  }
}

@end
