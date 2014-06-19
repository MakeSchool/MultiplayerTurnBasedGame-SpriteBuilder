//
//  FriendListScene.m
//  MultiplayerTurnBasedGame
//
//  Created by Benjamin Encz on 18/06/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "FriendListScene.h"
#import "PlayerCell.h"

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
  cellContent.nameLabel.string = @"Player";
  [cell addChild:cellContent];
  cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
  cell.contentSize = CGSizeMake(1.f, 50.f);
  
  return cell;
}

- (float) tableView:(CCTableView*)tableView heightForRowAtIndex:(NSUInteger) index {
  return 50;
}

- (NSUInteger) tableViewNumberOfRows:(CCTableView*) tableView {
  return 10;
}

@end
