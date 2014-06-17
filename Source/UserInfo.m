//
//  UserInfo.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 17/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "UserInfo.h"
#import <mgwuSDK/MGWU.h>

@interface UserInfo ()

@property (nonatomic, assign) SEL refreshCallback;
@property (nonatomic, weak) id refreshTarget;

@end

@implementation UserInfo

#pragma mark - Initializer

+ (instancetype)sharedUserInfo {
  static dispatch_once_t once;
  static id _sharedInstance = nil;
  
  dispatch_once(&once, ^{
    _sharedInstance = [[self alloc] init];
  });
  
  return _sharedInstance;
}

#pragma mark - Refreshing

- (void)refreshWithCallback:(SEL)callback onTarget:(id)target {
  self.refreshCallback = callback;
  self.refreshTarget = target;
  
  [MGWU getMyInfoWithCallback:@selector(refreshCompleted:) onTarget:self];
}

- (void)refreshCompleted:(NSDictionary *)userInfo {
  _name = userInfo[@"info"][@"name"];
  _username = userInfo[@"info"][@"username"];
  
  [self.refreshTarget performSelector:self.refreshCallback withObject:userInfo];
}

@end
