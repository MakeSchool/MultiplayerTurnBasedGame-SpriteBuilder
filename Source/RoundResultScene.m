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

NSString * const YOU_WIN = @"You win this round!";
NSString * const YOU_LOSE = @"You lose this round!";
NSString * const DRAW = @"It's a draw!";

@implementation RoundResultScene {
  CCSprite *_playerChoiceSprite;
  CCSprite *_opponentChoiceSprite;
  CCLabelTTF *_roundResultLabel;
}

- (void)onEnter {
  [super onEnter];
  
  NSAssert(self.game != nil, @"Game object needs to be assigned before prematch scene is displayed");
  
  NSInteger currentRound = currentRoundInGame(self.game);
  NSString *currentRoundString = [NSString stringWithFormat:@"%d", currentRound];
  NSDictionary *currentRoundData = self.game[@"gamedata"][currentRoundString];
  
  NSString *playerUsername = [[UserInfo sharedUserInfo] username];
  NSString *opponentUsername = getOpponentName(self.game);
  
  NSString *playerMove = currentRoundData[playerUsername];
  NSString *opponentMove = currentRoundData[opponentUsername];
  
  _playerChoiceSprite.spriteFrame = spriteFrameForChoice(playerMove);
  _opponentChoiceSprite.spriteFrame = spriteFrameForChoice(opponentMove);
  
  NSInteger winner = calculateWinner(playerMove, opponentMove);
  
  if (winner == 0) {
    _roundResultLabel.string = DRAW;
  } else if (winner == -1) {
    _roundResultLabel.string = YOU_WIN;
  } else if (winner == 1) {
    _roundResultLabel.string = YOU_LOSE;
  }
}

@end
