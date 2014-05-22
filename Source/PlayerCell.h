//
//  PlayerCell.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 21/05/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface PlayerCell : CCNode

@property (nonatomic, strong) CCLabelTTF *nameLabel;
@property (nonatomic, strong) CCLabelTTF *actionLabel;

@end
