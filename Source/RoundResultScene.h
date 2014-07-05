//
//  RoundResultScene.h
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "CCNode.h"

typedef NS_ENUM(NSInteger, RoundResultSceneNextScene)
{
  RoundResultSceneNextSceneInvalid,
  RoundResultSceneNextSceneMainScene,
  RoundResultSceneNextScenePreMatchScene,
};


@interface RoundResultScene : CCNode

@property (nonatomic, copy) NSDictionary *game;
@property (nonatomic, assign) RoundResultSceneNextScene nextScene;

@end
