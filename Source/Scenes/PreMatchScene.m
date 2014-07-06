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
#import "Constants.h"
#import "CCSpriteDownloadImage.h"
#import "UserInterfaceUtils.h"

NSString * const START_ROUND_STRING = @"It’s your turn to start this round!";
NSString * const FINISH_ROUND_STRING = @"It's your turn to finish this round!";
NSString * const WAITING_STRING = @"You are waiting on %@";

NSString * const GAME_OVER_WIN = @"Game ended. You won!";
NSString * const GAME_OVER_LOSE = @"Game ended. You lost!";
NSString * const GAME_OVER_DRAW = @"Game ended with a draw";

NSString * const ACTION_BUTTON_PLAY = @"Play";
NSString * const ACTION_BUTTON_OK = @"OK";
NSString * const ACTION_BUTTON_REMATCH = @"Rematch";


@implementation PreMatchScene {
  BOOL _playersTurn;
  
  CCButton *_actionButton;
  
  CCLabelTTF *_playerNameLabel;
  CCLabelTTF *_opponentNameLabel;
  CCLabelTTF *_currentRound;
  
  // round images
  CCSprite *_playerRound1;
  CCSprite *_playerRound2;
  CCSprite *_playerRound3;
  
  CCSprite *_opponentRound1;
  CCSprite *_opponentRound2;
  CCSprite *_opponentRound3;
  
  NSArray *_moveSpritesPlayer;
  NSArray *_moveSpritesOpponent;
  
  CCLabelTTF *_actionInfoLabel;
  
  CCSpriteDownloadImage *_playerSprite;
  CCSpriteDownloadImage *_opponentSprite;
}

- (void)onEnter {
  [super onEnter];
  
  _moveSpritesPlayer = @[_playerRound1, _playerRound2, _playerRound3];
  _moveSpritesOpponent = @[_opponentRound1, _opponentRound2, _opponentRound3];
  
  NSAssert(self.game != nil, @"Game object needs to be assigned before prematch scene is displayed");
  
  _playerNameLabel.string = @"You";
  _playerSprite.username = [[UserInfo sharedUserInfo] username];
  _opponentNameLabel.string = friendNameForUsername(getOpponentName(self.game));
  _opponentSprite.username = getOpponentName(self.game);
  _currentRound.string = [NSString stringWithFormat:@"%d",currentRoundInGame(self.game)];
    
  _playersTurn = isPlayersTurn(self.game);
  
  [self fillRoundLabels];
  
  if (currentRoundInGame(self.game) > ROUNDS_PER_GAME) {
    return;
  }
  
  // highlight current move
  if (_playersTurn) {
    CCSprite *currentMoveSprite = (CCSprite *) _moveSpritesPlayer[currentRoundInGame(self.game)-1];
    if (currentMoveSprite) {
      CCNode *particleSystem = [CCBReader load:@"CurrentRoundParticle"];
      particleSystem.positionType = CCPositionTypeNormalized;
      particleSystem.position = ccp(0.5, 0.5);
      [currentMoveSprite addChild:particleSystem];
    }
  } else {
    CCSprite *currentMoveSprite = (CCSprite *) _moveSpritesOpponent[currentRoundInGame(self.game)-1];
    if (currentMoveSprite) {
      CCNode *particleSystem = [CCBReader load:@"CurrentRoundParticle"];
      particleSystem.positionType = CCPositionTypeNormalized;
      particleSystem.position = ccp(0.5, 0.5);
      [currentMoveSprite addChild:particleSystem];
    }
  }
}

- (void)startGame {
  if (!_playersTurn) {
    [[CCDirector sharedDirector] popToRootScene];
  } else {
    if ([self.game[@"gamestate"] isEqualToString:GAME_STATE_COMPLETED]) {
      // start a new game, since old one is completed
      
      // but first check if we already have a match with this player
      if (!doesPlayerHaveMatchWithUser(getOpponentName(self.game))) {
        self.game = @{@"opponent":getOpponentName(self.game)};
      } else {
        [MGWU showMessage:@"You already have a match with this player" withImage:nil];
        return;
      }
    }
    
    CCScene *guessScene = [CCBReader loadAsScene:@"GameplayScene"];
    GameplayScene *gameplayScene = guessScene.children[0];
    gameplayScene.game = self.game;
    
    [[CCDirector sharedDirector] pushScene:guessScene];
  }
}

- (void)backButtonPressed {
  [[CCDirector sharedDirector] popToRootScene];
}

#pragma mark - Fill User Interface

- (void)fillRoundLabels {
  NSDictionary *round1 = self.game[@"gamedata"][@"1"];
  NSDictionary *round2 = self.game[@"gamedata"][@"2"];
  NSDictionary *round3 = self.game[@"gamedata"][@"3"];
  
  NSString *playerUsername = [[UserInfo sharedUserInfo] username];
  NSString *opponentUsername = getOpponentName(self.game);
  
  BOOL round1Complete = [[self.game[@"gamedata"][@"1"] allKeys] count] == MOVES_PER_ROUND;
  BOOL round2Complete = [[self.game[@"gamedata"][@"2"] allKeys] count] == MOVES_PER_ROUND;
  BOOL round3Complete = [[self.game[@"gamedata"][@"3"] allKeys] count] == MOVES_PER_ROUND;
  
  NSInteger moveNumber = [self.game[@"movecount"] integerValue];
  
  if ((moveNumber % MOVES_PER_ROUND) == 0) {
    _actionInfoLabel.string = START_ROUND_STRING;
  } else {
    _actionInfoLabel.string = FINISH_ROUND_STRING;
  }
  
  if (!_playersTurn) {
    // it's the other's players turn
    _actionInfoLabel.string = [NSString stringWithFormat:WAITING_STRING, friendNameForUsername(getOpponentName(self.game))];
    [_actionButton setTitle:ACTION_BUTTON_OK];
  } else {
    [_actionButton setTitle:ACTION_BUTTON_PLAY];
  }
  
  if ([self.game[@"movecount"] integerValue] == ROUNDS_PER_GAME * MOVES_PER_ROUND) {
    NSInteger winner = calculateWinnerOfGame(self.game);
    
    if (winner == 0) {
      _actionInfoLabel.string = GAME_OVER_DRAW;
    } else if (winner == -1) {
      _actionInfoLabel.string = GAME_OVER_WIN;
    } else if (winner == 1) {
      _actionInfoLabel.string = GAME_OVER_LOSE;
    }
    
    _currentRound.string = @"-";
    
    [_actionButton setTitle:ACTION_BUTTON_REMATCH];
    // allow player to rematch
    _playersTurn = YES;
  }
  
  NSString *playerMoveRound1 = round1[playerUsername];
  playerMoveRound1 = playerMoveRound1 ? playerMoveRound1 : @"_";
  _playerRound1.spriteFrame = spriteFrameForChoice(playerMoveRound1);
  NSString *opponentMoveRound1 = round1[opponentUsername];
  // only show choice of opponent if this round is complete
  if (opponentMoveRound1) {
    opponentMoveRound1 = round1Complete ? opponentMoveRound1 : @"?";
  }
  opponentMoveRound1 = opponentMoveRound1 ? opponentMoveRound1: @"_";
  _opponentRound1.spriteFrame = spriteFrameForChoice(opponentMoveRound1);
  
  NSString *playerMoveRound2 = round2[playerUsername];
  playerMoveRound2 = playerMoveRound2 ? playerMoveRound2 : @"_";
  _playerRound2.spriteFrame = spriteFrameForChoice(playerMoveRound2);
  NSString *opponentMoveRound2 = round2[opponentUsername];
  // only show choice of opponent if this round is complete
  if (opponentMoveRound2) {
    opponentMoveRound2 = round2Complete ? opponentMoveRound2 : @"?";
  }
  opponentMoveRound2 = opponentMoveRound2 ? opponentMoveRound2: @"_";
  _opponentRound2.spriteFrame = spriteFrameForChoice(opponentMoveRound2);

  NSString *playerMoveRound3 = round3[playerUsername];
  playerMoveRound3 = playerMoveRound3 ? playerMoveRound3 : @"_";
  _playerRound3.spriteFrame = spriteFrameForChoice(playerMoveRound3);
  NSString *opponentMoveRound3 = round3[opponentUsername];
  // only show choice of opponent if this round is complete
  if (opponentMoveRound3) {
    opponentMoveRound3 = round3Complete ? opponentMoveRound3 : @"?";
  }
  opponentMoveRound3 = opponentMoveRound3 ? opponentMoveRound3: @"_";
  _opponentRound3.spriteFrame = spriteFrameForChoice(opponentMoveRound3);
}

@end
