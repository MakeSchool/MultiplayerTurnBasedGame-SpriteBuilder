//
//  GameDataUtils.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#ifndef MultiplayerTurnBasedGame_GameDataUtils_h
#define MultiplayerTurnBasedGame_GameDataUtils_h

/**
 Returns the username of the opponent in the provided game.
 */
extern NSString* getOpponentName(NSDictionary *gameData);

/**
 If the provided user is a friend of the active user, this 
 method returns the full Facebook name.
 */
extern NSString* friendNameForUsername(NSString *username);

/**
 If player has a match with this friend, this method returns the game id.
 If there's no match, this method returns nil.
 */
extern NSNumber* doesPlayerHaveMatchWithUser(NSString *username);

/**
 Returns a list of friends with whom the current player does not have matches yet.
 Returned list is an array of NSStrings
 */
extern NSArray* friendsWithoutOpenMatches();

/**
 Returns a match dictionary for the provided match ID. If user does not have a match with the provided
 id, this function returns nil.
 */
extern NSDictionary* getMatchById(NSNumber *matchID);

/**
 Returns whether or not the latest round of the game is completed. Round 1 is completed after 2 moves, Round 2
 is completed after 4 moves, etc.
 */
extern BOOL isCurrentRoundCompleted(NSDictionary *game);

/**
 Checks wether or not the provided game is completed.
 */
extern BOOL isGameCompleted(NSDictionary *game);

/**
 Checks if it's the players turn in the provided game.
 */
extern BOOL isPlayersTurn(NSDictionary *game);

/**
 Returns the current round in the provided game. Move 3 is part of Round 2, Move 5 is part of Round 3, etc.
 */
extern NSInteger currentRoundInGame(NSDictionary *game);

/** 
 Performs the specified move for the provided player and game. This function sends the move to the MGWU server. After
 sending is complete the callback is called on the target.
 */
extern void performMoveForPlayerInGame(NSString *move, NSString *playerName, NSDictionary* game, id target, SEL callback);

/**
 Calculates the winner of the two provided choices.
 0 = draw between both choices
 -1 = choice 1 wins
 +1 = choice 2 wins
 */
extern NSInteger calculateWinnerOfRound(NSString *movePlayer1, NSString *movePlayer2);

/**
 Returns the winner of the provided game.
 0 = draw between both players
 -1 = player wins
 +1 = opponent wins
 */
extern NSInteger calculateWinnerOfGame(NSDictionary *game);

#endif
