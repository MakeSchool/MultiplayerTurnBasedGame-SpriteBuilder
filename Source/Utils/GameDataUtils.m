//
//  GameDataUtils.c
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 19/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameDataUtils.h"
#import "Constants.h"
#import "UserInfo.h"

NSString* getOpponentName(NSDictionary *gameData) {
  // get all players in game
  NSArray *players = gameData[@"players"];
  NSString *opponentName;
  if (players) {
    if ([[players objectAtIndex:0] isEqualToString:[UserInfo sharedUserInfo].username])
      // check if first player is user, if yes, then second player is opponent
      opponentName = [players objectAtIndex:1];
    else
      // else the first player is the opponent and the second player is the suer
      opponentName = [players objectAtIndex:0];
    return opponentName;
    
  } else {
    return gameData[@"opponent"];
  }
}

NSString* friendNameForUsername(NSString *username) {
  for (NSMutableDictionary *friend in [UserInfo sharedUserInfo].friends)
  {
    //Add friendName to game if you're friends
    if ([[friend objectForKey:@"username"] isEqualToString:username])
    {
      return [friend objectForKey:@"name"];
    }
  }
  
  return @"Random Player";
}

NSNumber* doesPlayerHaveMatchWithUser(NSString *username) {
  NSArray *games = [UserInfo sharedUserInfo].allGames;
  
  for (NSDictionary *game in games) {
    
    if ([game[@"gamestate"] isEqualToString:GAME_STATE_COMPLETED]) {
      // don't count completed matches as matches with user
      continue;
    }
    
    for (NSString *playerID in  game[@"players"]) {
      // if the provided username is a player in one of our games, return that game
      if ([playerID isEqualToString:username]) {
        return game[@"gameid"];
      }
    }
  }
  
  return nil;
}

NSDictionary* getMatchById(NSNumber *matchID) {
  NSArray *games = [UserInfo sharedUserInfo].allGames;
  
  for (NSDictionary *game in games) {
    if ([game[@"gameid"] isEqualToNumber:matchID]) {
      return game;
    }
  }
  
  return nil;
}

void performMoveForPlayerInGame(NSString *move, NSString *playerName, NSDictionary* game, id target, SEL callback) {
  // calculate next move number
  int nextMoveNumber = [game[@"movecount"] intValue] + 1;
  int gameID =  [game[@"gameid"] intValue];
  
  NSString *opponentUserName = getOpponentName(game);
  NSString *playerUserName = playerName;
  NSString *newGameState = game[@"gamestate"];
  
  if (newGameState == nil) {
    // if we have no game state, then next game state is "started"
    newGameState = GAME_STATE_STARTED;
  } else if (nextMoveNumber > 1) {
    // if we have a move in this game, then next game state is "in progress"
    newGameState = GAME_STATE_IN_PROGRESS;
  }
  
  // add a move to the game data
  NSMutableDictionary *gameData = game[@"gamedata"];
  
  if (!gameData) {
    // if we don't have any game data yet, create a new dictionay
    gameData = [NSMutableDictionary dictionary];
  }
  
  // calculate current round (move 0 and 1 are part of round 1, move 2 and 3 are part of round 2, etc.)
  NSInteger currentRound = currentRoundInGame(game);
  NSString *currentRoundString = [NSString stringWithFormat:@"%i",currentRound];
  
  /*
   All individual moves of this game are stored in the "gamedata" dictionary. The key is used
   as the round number. For each round we store another dictionary with the username as the key and
   the move as the value.
   
   {
    1:
      {player1: scissors
      player2: scissors}
    2:
      {player1: scissors
      player1: scissors}
    3:
      {player1: scissors
      player1: scissors}
   }
   */
  
  // retrieve game data for the current round
  NSMutableDictionary *currentRoundGameData = game[@"gamedata"][currentRoundString];
  
  // if we don't have a dictionary entry for this round yet - let's create a new dictionary
  if (!currentRoundGameData) {
    currentRoundGameData = [NSMutableDictionary dictionary];
    gameData[currentRoundString] = currentRoundGameData;
  }
  
  currentRoundGameData[playerUserName] = move;
  
  // After 6 rounds, mark game as completed
  if (nextMoveNumber == ROUNDS_PER_GAME * MOVES_PER_ROUND) {
    newGameState = GAME_STATE_COMPLETED;
    NSInteger winner = calculateWinnerOfGame(game);
    
    // store the winner on the server
    if (winner == -1) {
      gameData[@"winner"] = playerUserName;
    } else if (winner == 1) {
      gameData[@"winner"] = opponentUserName;
    }
  }
  
  // submit the move to the MGWU server
  [MGWU move:@{@"selectedElement":move} withMoveNumber:nextMoveNumber forGame:gameID withGameState:newGameState withGameData:gameData againstPlayer:opponentUserName withPushNotificationMessage:@"Round completed" withCallback:callback onTarget:target];
}

BOOL isCurrentRoundCompleted(NSDictionary *game) {
  // if we have an even amount of moves, then this round is completed
  return (([game[@"movecount"] intValue] % MOVES_PER_ROUND) == 0);
}

NSInteger currentRoundInGame(NSDictionary *game) {
  NSInteger currentRound = [game[@"movecount"] intValue] / 2;
  currentRound += 1;
    
  return currentRound;
}

BOOL isGameCompleted(NSDictionary *game) {
  if ([game[@"gamestate"] isEqualToString:GAME_STATE_COMPLETED]) {
    return YES;
  } else {
    return NO;
  }
}


/*
 This method calculates the winner of a round, based on the choice of Rock, Paper, Scissors by each player.
 */
NSInteger calculateWinnerOfRound(NSString *movePlayer1, NSString *movePlayer2) {

  // if both players chose the same move, this is a draw -> return 0;
  if ([movePlayer1 isEqualToString:movePlayer2]) {
    return 0;
  }

  /*
   Otherwise, put both moves in an array and use a sorting algorithm to determine which choice wins.
   Whichever choice will be at choiceArray[0] after sorting will be the winner.
   */
  NSArray *choiceArray = @[movePlayer1, movePlayer2];
  
  // perform sorting
  NSArray *sortedArray = [choiceArray sortedArrayUsingComparator:^NSComparisonResult(NSString *choice1, NSString *choice2) {
    NSComparisonResult comparisonResult = NSOrderedSame;
    
    if ([choice1 isEqualToString:CHOICE_SCISSORS]) {
      if ([choice2 isEqualToString:CHOICE_ROCK]) {
        // scissors loses against rock
        comparisonResult = NSOrderedDescending;
      } else if ([choice2 isEqualToString:CHOICE_PAPER]) {
        // scissors wins against paper
        comparisonResult = NSOrderedAscending;
      }
    }
    
    if ([choice1 isEqualToString:CHOICE_ROCK]) {
      if ([choice2 isEqualToString:CHOICE_PAPER]) {
        // rock loses against paper
        comparisonResult = NSOrderedDescending;
      } else if ([choice2 isEqualToString:CHOICE_SCISSORS]) {
        // rock wins against scissors
        comparisonResult = NSOrderedAscending;
      }
    }
    
    if ([choice1 isEqualToString:CHOICE_PAPER]) {
      if ([choice2 isEqualToString:CHOICE_SCISSORS]) {
        // paper loses against scissors
        comparisonResult = NSOrderedDescending;
      } else if ([choice2 isEqualToString:CHOICE_ROCK]) {
        // paper wins against rock
        comparisonResult = NSOrderedAscending;
      }
    }
    
    return comparisonResult;
  }];
  
  
  if ([sortedArray indexOfObject:movePlayer1] < [sortedArray indexOfObject:movePlayer2]) {
    // if player 1's choice is before player 2's choice in the array -> player 1 wins
    return -1;
  } else {
    // else, player 2 wins
    return 1;
  }
}

/*
 Calculate the winner of the game by summning up the results of the individual games.
 */
NSInteger calculateWinnerOfGame(NSDictionary *game) {
  NSInteger scorePlayer = 0;
  NSInteger scoreOpponent = 0;
  
  NSString *opponentUserName = getOpponentName(game);
  NSString *playerUserName = [[UserInfo sharedUserInfo] username];
  NSDictionary *gamedata = game[@"gamedata"];
  
  for (int i = 1; i <= ROUNDS_PER_GAME; i++) {
    NSString *currentRoundString = [NSString stringWithFormat:@"%d", i];
    
    NSString *playerMoveCurrentRound = gamedata[currentRoundString][playerUserName];
    NSString *opponentMoveCurrentRound = gamedata[currentRoundString][opponentUserName];
    NSInteger winnerCurrentRound = calculateWinnerOfRound(playerMoveCurrentRound, opponentMoveCurrentRound);
    
    /*
     For each round, increase the score for the user or the opponent, depending on who won the individual round.
     */
    if (winnerCurrentRound == -1) {
      scorePlayer++;
    } else if (winnerCurrentRound == 1) {
      scoreOpponent++;
    }
  }
  
  if (scorePlayer == scoreOpponent) {
    // a draw
    return 0;
  } else if (scorePlayer > scoreOpponent) {
    // user wins
    return -1;
  } else if (scorePlayer < scoreOpponent) {
    // opponent wins
    return +1;
  }
 
  // should never be reached
  return 0;
}

BOOL isPlayersTurn(NSDictionary *game) {
  BOOL playersTurn = NO;
  
  NSString *turnPlayerUsername = game[@"turn"];
  
  if (!game[@"gamestate"]) {
    // if we're just starting this game, it is our turn
    playersTurn = YES;
  } else {
    playersTurn = ([turnPlayerUsername isEqualToString:[[UserInfo sharedUserInfo] username]]);
  }
    
  return playersTurn;
}

NSArray* friendsWithoutOpenMatches() {
  NSMutableArray *friendsWithoutOpenMatches = [NSMutableArray array];
  
  for (NSDictionary *friend in [[UserInfo sharedUserInfo] friends]) {
    NSString *friendUsername = friend[@"username"];
    if (!doesPlayerHaveMatchWithUser(friendUsername)) {
      [friendsWithoutOpenMatches addObject:friendUsername];
    }
  }
  
  return friendsWithoutOpenMatches;
}
