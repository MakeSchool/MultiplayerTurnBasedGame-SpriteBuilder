//
//  CCSpriteDownloadImage.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCSprite.h"

/**
 This is a CCSprite subclass that will download a facebook profile picture and cache
 the result in memory and on the disk. To trigger download set the "username" property.
 Once the download is completed this CCSprite subclass will update its texture to the downloaded
 image.
 */
@interface CCSpriteDownloadImage : CCSprite

/**
 Setting this facebook username will trigger the download of the profile picture.
 */
@property (nonatomic, copy) NSString *username;

@end
