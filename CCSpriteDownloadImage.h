//
//  CCSpriteDownloadImage.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

@interface CCSpriteDownloadImage : CCSprite

@property (nonatomic, copy) NSString *username;

- (void)setDownloadImage:(NSString *)urlString;

@end
