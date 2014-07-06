//
//  GameDataUtils.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#ifndef MultiplayerTurnBasedGame_GameDataUtils_h
#define MultiplayerTurnBasedGame_GameDataUtils_h

extern NSString* getOpponentName(NSDictionary *gameData);
extern NSString* friendNameForUsername(NSString *username);

/**
 If player has a match with this friend, this method returns the game id.
 If there's no match, this method returns nil.
 */
extern NSNumber* doesPlayerHaveMatchWithUser(NSString *username);

extern NSArray* friendsWithoutOpenMatches();

extern NSDictionary* getMatchById(NSNumber *matchID);

extern BOOL isCurrentRoundCompleted(NSDictionary *game);

extern BOOL isGameCompleted(NSDictionary *game);

extern BOOL isPlayersTurn(NSDictionary *game);

extern NSInteger currentRoundInGame(NSDictionary *game);

extern void performMoveForPlayerInGame(NSString *move, NSString *playerName, NSDictionary* game, id target, SEL callback);

/**
 0 = draw between both choices
 -1 = choice 1 wins
 +1 = choice 2 wins
 */
extern NSInteger calculateWinnerOfRound(NSString *movePlayer1, NSString *movePlayer2);

/**
 0 = draw between both players
 -1 = player wins
 +1 = opponent wins
 */
extern NSInteger calculateWinnerOfGame(NSDictionary *game);

#endif
