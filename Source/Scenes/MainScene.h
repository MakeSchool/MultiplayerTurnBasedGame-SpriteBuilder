//
//  MainScene.h
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "CCNode.h"

/**
 This scene represent the main list of games, displayed immediately after the game starts.
 */

@interface MainScene : CCNode <CCTableViewDataSource>

- (void)loadedUserInfo:(NSDictionary *)userInfo;

@end
