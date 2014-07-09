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
	CCButton *_rematchButton;
	
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
	
	NSAssert(_game != nil, @"Game object needs to be assigned before game scene is displayed");
	
	_opponent = _game[@"opponent"];
	
	_playerNameLabel.string = [UserInfo shortNameFromName:[UserInfo sharedUserInfo].name];
	_playerSprite.username = [[UserInfo sharedUserInfo] username];
	
	NSString *opponentName = _game[@"opponentName"];
	_opponentNameLabel.string = [UserInfo shortNameFromName:opponentName];
	_opponentSprite.username = _opponent;
	
	[self reload];
}

- (void)reload
{
	_gameState = _game[@"gamestate"];
	_gameData = _game[@"gamedata"];
	
	if (!_gameState)
	{
		//No game exists, create starting game state and game data
		_gameState = @"started";
		_gameData = [@{@"number":@10} mutableCopy];
	}
	
	_oneButton.visible = YES;
	_twoButton.visible = YES;
	_rematchButton.visible = NO;
	_titleBarLabel.string = @"Play!";
	_numberLabel.string = [NSString stringWithFormat:@"%@", _gameData[@"number"]];
	
	if ([_gameState isEqualToString:@"ended"])
	{
		//Game is over, disable buttons
		_titleBarLabel.string = @"Game Over";
		if ([_gameData[@"winner"] isEqualToString:_opponent])
			_numberLabel.string = @"You Lost";
		else
			_numberLabel.string = @"You Won!";
		_oneButton.visible = NO;
		_twoButton.visible = NO;
		_rematchButton.visible = YES;
	}
	else if ([_game[@"turn"] isEqualToString:_opponent])
	{
		//Waiting for opponent, disable buttons
		_titleBarLabel.string = @"Waiting";
		_oneButton.visible = NO;
		_twoButton.visible = NO;
	}
}

#pragma mark - Button Callbacks

- (void)onePressed {
	[self submitMove:1];
}

- (void)twoPressed {
	[self submitMove:2];
}

- (void)submitMove:(int)count {
	
	//Set gameid and movenumber, these will be 0 if you're just starting the game
	int gameId = [_game[@"gameid"] intValue];
	int moveNumber = [_game[@"movecount"] intValue] + 1;
	if (moveNumber > 1)
		_gameState = @"inprogress";
	
	//Create move dictionary
	NSDictionary *moveDict = @{@"count":@(count)};
	
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
	
	//Set push message
	NSString *message = [NSString stringWithFormat:@"%@ played you in Nim, play them back!", [UserInfo shortNameFromName:[UserInfo sharedUserInfo].name]];
	
	//Send move to server
	[MGWU move:moveDict withMoveNumber:moveNumber forGame:gameId withGameState:_gameState withGameData:_gameData againstPlayer:_opponent withPushNotificationMessage:message withCallback:@selector(gotGame:) onTarget:self];
}

- (void)gotGame:(NSMutableDictionary*)game {
	_game = game;
	//Reload view based on received game
	[self reload];
}

- (void)rematchPressed {
	_game = @{@"opponent":_opponent, @"opponentName":_game[@"opponentName"]};
	[self reload];
}

- (void)backButtonPressed {
	[[CCDirector sharedDirector] popToRootScene];
}

@end
