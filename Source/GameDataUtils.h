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
extern NSNumber* doesPlayerHaveMatchWithFriend(NSString *username);

#endif
