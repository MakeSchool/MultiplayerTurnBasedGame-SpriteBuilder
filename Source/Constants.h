//
//  Constants.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 01/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#ifndef MultiplayerTurnBasedGame_Constants_h
#define MultiplayerTurnBasedGame_Constants_h

static NSString * const GAME_STATE_STARTED = @"started";
static NSString * const GAME_STATE_IN_PROGRESS = @"inprogress";
static NSString * const GAME_STATE_COMPLETED = @"ended";

static NSInteger MOVES_PER_ROUND = 2;
static NSInteger ROUNDS_PER_GAME = 3;

static NSString * const CHOICE_SCISSORS = @"Scissors";
static NSString * const CHOICE_ROCK = @"Rock";
static NSString * const CHOICE_PAPER = @"Paper";

/* Game Data for this game */

/*
 1:
    player1: scissors
    player2: scissors
 
 2:
    player1: scissors
    player1: scissors

 3:
   player1: scissors
   player1: scissors
 */

#endif