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
#import "PreMatchScene.h"

@implementation FriendListScene {
  CCNode *_tableViewContentNode;
  CCTableView *_tableView;
  NSMutableDictionary *_playerCellForIndex;
}

#pragma mark - Lifecycle

- (void)dealloc {
  [_tableView setTarget:nil selector:nil];
}

- (void)didLoadFromCCB {
  _tableView = [[CCTableView alloc] init];
  [_tableViewContentNode addChild:_tableView];
  _tableView.contentSizeType = CCSizeTypeNormalized;
  _tableView.contentSize = CGSizeMake(1.f, 1.f);
  [_tableView setTarget:self selector:@selector(tableViewCellSelected:)];
  _tableView.dataSource = self;
}

#pragma mark - TableView Content Creation

- (PlayerCell *)cellContentForRowAtIndex:(NSUInteger)index {
  if (!_playerCellForIndex) {
    _playerCellForIndex = [NSMutableDictionary dictionary];
  }
  
  if (_playerCellForIndex[@(index)]) {
    return _playerCellForIndex[@(index)];
  } else {
    PlayerCell *cellContent = (PlayerCell *)[CCBReader load:@"PlayerCell"];
    NSString *friendName = ([UserInfo sharedUserInfo].friends[index])[@"name"];
    NSString *friendUsername = ([UserInfo sharedUserInfo].friends[index])[@"username"];
    
    cellContent.nameLabel.string = friendName;
    cellContent.player = [UserInfo sharedUserInfo].friends[index];
    
    if (doesPlayerHaveMatchWithUser(friendUsername)) {
      cellContent.actionLabel.string = @"SHOW";
      cellContent.actionType = PlayerCellActionTypeShowGame;
    } else {
      cellContent.actionLabel.string = @"PLAY";
      cellContent.actionType = PlayerCellActionTypeStartGame;
    }

    _playerCellForIndex[@(index)] = cellContent;

    return cellContent;
  }
}

#pragma mark - TableView Cell Selection

- (void)tableViewCellSelected:(CCTableViewCell*)sender {
  PlayerCell *selectedPlayerCell = [self cellContentForRowAtIndex:_tableView.selectedRow];
  
  NSDictionary *gameInfo = nil;
  
  if (selectedPlayerCell.actionType == PlayerCellActionTypeShowGame) {
    NSNumber *matchID = doesPlayerHaveMatchWithUser(selectedPlayerCell.player[@"username"]);
    gameInfo = getMatchById(matchID);
  } else if (selectedPlayerCell.actionType == PlayerCellActionTypeStartGame) {
    gameInfo = @{@"opponent":selectedPlayerCell.player[@"username"]};
  }
  
  CCScene *scene = [CCBReader loadAsScene:@"PreMatchScene"];
  PreMatchScene *prematchScene = scene.children[0];
  prematchScene.game = gameInfo;
  [[CCDirector sharedDirector] pushScene:scene];
}

#pragma mark - CCTableViewDataSource Protocol

- (CCTableViewCell*)tableView:(CCTableView*)tableView nodeForRowAtIndex:(NSUInteger)index {
  CCTableViewCell *cell = [[CCTableViewCell alloc] init];
  
  [cell addChild:[self cellContentForRowAtIndex:index]];
  cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
  cell.contentSize = CGSizeMake(1.f, 50.f);

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
  // pop back to previous scene when back button is pressed
  [[CCDirector sharedDirector] popScene];
}

- (void)inviteFriends {
  // invite facebook friends
  [MGWU inviteFriendsWithMessage:@"I'm challenging you to play Rock, Paper, Scissors!"];
}

@end
