//
//  GameScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Ashutosh Desai on 7/8/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameScene.h"
#import "UserInfo.h"
#import "CCSpriteDownloadImage.h"

@implementation GameScene {
	CCLabelTTF *_titleBarLabel;
	CCLabelTTF *_numberLabel;
	
	CCButton *_oneButton;
	CCButton *_twoButton;
	
	CCLabelTTF *_playerNameLabel;
	CCLabelTTF *_opponentNameLabel;
	
	CCSpriteDownloadImage *_playerSprite;
	CCSpriteDownloadImage *_opponentSprite;
	
	NSString *_opponent;
	NSString *_gameState;
	NSMutableDictionary *_gameData;
}

#pragma mark - Lifecycle

- (void)onEnter {
	[super onEnter];
	
	NSAssert(self.game != nil, @"Game object needs to be assigned before game scene is displayed");
	
	_opponent = self.game[@"opponent"];
	
	_playerNameLabel.string = [UserInfo shortNameFromName:[UserInfo sharedUserInfo].name];
	_playerSprite.username = [[UserInfo sharedUserInfo] username];
	
	NSString *opponentName = self.game[@"opponentName"];
	if (!opponentName)
		_opponentNameLabel.string = @"Random Player";
	else
		_opponentNameLabel.string = [UserInfo shortNameFromName:opponentName];
	_opponentSprite.username = _opponent;
	
	[self reload];
}

- (void)reload
{
	_gameState = self.game[@"gamestate"];
	
	if (!_gameState)
	{
		//No game exists, allow user to start a new game
		_gameState = @"started";
		_gameData = [@{@"number":@10} mutableCopy];
		_titleBarLabel.string = @"Start Game!";
	}
	else if ([_gameState isEqualToString:@"started"])
	{
		//If game was already started, update state to inprogress
		_gameState = @"inprogress";
	}
	else if ([_gameState isEqualToString:@"ended"])
	{
		//Game is over, disable buttons
		if ([_gameData[@"winner"] isEqualToString:_opponent])
			_titleBarLabel.string = @"You Lost";
		else
			_titleBarLabel.string = @"You Won!";
		_oneButton.visible = NO;
		_twoButton.visible = NO;
	}
	else if ([self.game[@"turn"] isEqualToString:_opponent])
	{
		//Waiting for opponent, disable buttons
		_titleBarLabel.string = @"Waiting";
		_oneButton.visible = NO;
		_twoButton.visible = NO;
	}
	
	_numberLabel.string = [NSString stringWithFormat:@"%@", _gameData[@"number"]];
}

#pragma mark - Button Callbacks

- (void)onePressed {
	[self submitMove:1];
}

- (void)twoPressed {
	[self submitMove:2];
}

- (void)submitMove:(int)count {
	
	//Reduce the number based on which button was clicked
	int newNumber = [_gameData[@"number"] intValue] - count;
	if (newNumber < 1)
	{
		//If the number has reached 0 (or -1), set the game state to ended and set the winner to opponent
		newNumber = 0;
		_gameState = @"ended";
		_gameData[@"winner"] = _opponent;
	}
	_gameData[@"number"] = @(newNumber);
	
	//Set movenumber and gameid
	int moveNumber = [_game[@"movecount"] intValue] + 1;
	int gameId = [_game[@"gameid"] intValue];
	
	//Create move dictionary
	NSDictionary *moveDict = @{@"count":@(count)};
	
	//Set push message
	NSString *message = [NSString stringWithFormat:@"%@ played you in Nim, play them back!", [UserInfo shortNameFromName:[UserInfo sharedUserInfo].name]];
	
	//Send move to server
	[MGWU move:moveDict withMoveNumber:moveNumber forGame:gameId withGameState:_gameState withGameData:_gameData againstPlayer:_opponent withPushNotificationMessage:message withCallback:@selector(gotGame:) onTarget:self];
}

- (void)gotGame:(NSMutableDictionary*)game {
	self.game = game;
	//Reload view based on received game
	[self reload];
}

- (void)backButtonPressed {
	[[CCDirector sharedDirector] popToRootScene];
}

@end
