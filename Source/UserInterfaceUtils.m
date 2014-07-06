//
//  UserInterfaceUtils.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 05/07/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "UserInterfaceUtils.h"
#import "Constants.h"

CCSpriteFrame* spriteFrameForChoice(NSString *choice) {
  CCSpriteFrame *spriteFrame = nil;
  
  if ([choice isEqualToString:CHOICE_SCISSORS]) {
    spriteFrame = [CCSpriteFrame frameWithImageNamed:@"Resources/Paper_Rock_Scissors/Icon-Scissors-Small.png"];
  } else if ([choice isEqualToString:CHOICE_ROCK]) {
    spriteFrame = [CCSpriteFrame frameWithImageNamed:@"Resources/Paper_Rock_Scissors/Icon-Rock-Small.png"];
  } else if ([choice isEqualToString:CHOICE_PAPER]) {
    spriteFrame = [CCSpriteFrame frameWithImageNamed:@"Resources/Paper_Rock_Scissors/Icon-Paper-Small.png"];
  } else if ([choice isEqualToString:@"?"]) {
    spriteFrame = [CCSpriteFrame frameWithImageNamed:@"Resources/Paper_Rock_Scissors/Icon-Unknown-Small.png"];
  } else if ([choice isEqualToString:@"_"]) {
    spriteFrame = [CCSpriteFrame frameWithImageNamed:@"Resources/Paper_Rock_Scissors/Icon-Blank-Small.png"];
  }
  
  return spriteFrame;
}