//
//  PlayerCell.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 21/05/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

typedef NS_ENUM(NSInteger, PlayerCellActionType) {
  PlayerCellActionTypeNone,
  PlayerCellActionTypeShowGame,
  PlayerCellActionTypeStartGame
};

@interface PlayerCell : CCNode

@property (strong) CCLabelTTF *nameLabel;
@property (strong) CCLabelTTF *actionLabel;

@property (assign) PlayerCellActionType actionType;
@property (nonatomic, copy) NSDictionary *player;

@end
