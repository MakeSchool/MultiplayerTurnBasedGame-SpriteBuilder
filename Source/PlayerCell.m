//
//  PlayerCell.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 21/05/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "PlayerCell.h"
#import "CCSpriteDownloadImage.h"

@implementation PlayerCell {
  CCSpriteDownloadImage *_playerImage;
}

- (void)setPlayer:(NSDictionary *)player {
  _player = [player copy];
  
  [_playerImage setUsername:_player[@"username"]];
}

- (void)setPlayerUsername:(NSString *)playerUsername {
  _playerUsername = [playerUsername copy];
  
  [_playerImage setUsername:_playerUsername];
}

@end
