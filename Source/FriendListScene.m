//
//  FriendListScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 18/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "FriendListScene.h"
#import "PlayerCell.h"
#import "UserInfo.h"
#import "GameDataUtils.h"

@implementation FriendListScene {
  CCNode *_tableViewContentNode;
  CCTableView *_tableView;
}

#pragma mark - Lifecycle

- (void)didLoadFromCCB {
  _tableView = [[CCTableView alloc] init];
  [_tableViewContentNode addChild:_tableView];
  _tableView.contentSizeType = CCSizeTypeNormalized;
  _tableView.contentSize = CGSizeMake(1.f, 1.f);
  [_tableView setTarget:self selector:@selector(tableViewCellSelected:)];
  _tableView.dataSource = self;
}

- (void)tableViewCellSelected:(CCTableViewCell*)sender {
  CCLOG(@"Index selected:%d", _tableView.selectedRow);
}

#pragma mark - CCTableViewDataSource Protocol

- (CCTableViewCell*)tableView:(CCTableView*)tableView nodeForRowAtIndex:(NSUInteger)index {
  CCTableViewCell *cell = [[CCTableViewCell alloc] init];
  
  PlayerCell *cellContent = (PlayerCell *)[CCBReader load:@"PlayerCell"];
  NSString *friendName = ([UserInfo sharedUserInfo].friends[index])[@"name"];
  NSString *friendUsername = ([UserInfo sharedUserInfo].friends[index])[@"username"];
  cellContent.nameLabel.string = friendName;
  [cell addChild:cellContent];
  cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
  cell.contentSize = CGSizeMake(1.f, 50.f);
  
  if (doesPlayerHaveMatchWithFriend(friendUsername)) {
    cellContent.actionLabel.string = @"SHOW";
  } else {
    cellContent.actionLabel.string = @"PLAY";
  }
  
  return cell;
}

- (float) tableView:(CCTableView*)tableView heightForRowAtIndex:(NSUInteger) index {
  return 50;
}

- (NSUInteger) tableViewNumberOfRows:(CCTableView*) tableView {
  return [[UserInfo sharedUserInfo].friends count];
}

#pragma mark - Button Callbacks

- (void)backButtonPressed {
  [[CCDirector sharedDirector] popScene];
}

@end
