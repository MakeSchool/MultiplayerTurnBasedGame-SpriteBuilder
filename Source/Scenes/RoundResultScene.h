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

/**
 This property allows caller to configure which scene is displayed after the RoundResultScene.
 */
@property (nonatomic, assign) RoundResultSceneNextScene nextScene;

@end
