//
//  PlayerCell.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 21/05/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface PlayerCell : CCNode

@property (strong) CCLabelTTF *nameLabel;
@property (strong) CCLabelTTF *actionLabel;

// either set player or playerUsername in order for FB profile picture to load
@property (nonatomic, copy) NSDictionary *player;

@end
