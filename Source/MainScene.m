//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "CCTableView.h"
#import "PlayerCell.h"
#import "MGWU.h"
#import "PreMatchScene.h"
#import "UserInfo.h"
#import "GameDataUtils.h"
#import "SectionCell.h"

@implementation MainScene {
    CCNode *_tableViewContentNode;
    CCTableView *_tableView;
    CCTextField *_textField;
  
  NSMutableArray *_allCells;
}

#pragma mark - Lifecycle

- (void)didLoadFromCCB {
    _tableView = [[CCTableView alloc] init];
    [_tableViewContentNode addChild:_tableView];
    _tableView.contentSizeType = CCSizeTypeNormalized;
    _tableView.contentSize = CGSizeMake(1.f, 1.f);
    [_tableView setTarget:self selector:@selector(tableViewCellSelected:)];
  
  _allCells = [NSMutableArray array];

    _tableView.dataSource = self;
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
  
}

#pragma mark - MGWUSDK Callbacks

- (void)loadedUserInfo:(NSDictionary *)userInfo {
    NSLog(@"Test");
  _allCells = [NSMutableArray array];
  
  [_allCells addObject:@"your turn"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesYourTurn];
  [_allCells addObject:@"waiting on"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesTheirTurn];
  [_allCells addObject:@"completed"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesCompleted];
  
  [_tableView reloadData];
}

- (void)receivedRandomGame:(NSDictionary *)gameInfo {

  if (gameInfo[@"gameid"]) {
    // if server returns game, continue that game
  } else {
    // if the server responds with no existing random game, start a new one
  }
  
  CCScene *scene = [CCBReader loadAsScene:@"PreMatchScene"];
  PreMatchScene *prematchScene = scene.children[0];
  prematchScene.game = gameInfo;
  [[CCDirector sharedDirector] pushScene:scene];
}

#pragma mark - CCTableViewDataSource Protocol

- (CCTableViewCell*)tableView:(CCTableView*)tableView nodeForRowAtIndex:(NSUInteger)index {
    CCTableViewCell *cell = [[CCTableViewCell alloc] init];
  
  id currentCell = _allCells[index];
  
  if ([currentCell isKindOfClass:[NSString class]]) {
    // this is a section
    SectionCell *cellContent = (SectionCell *)[CCBReader load:@"SectionCell"];
    cellContent.sectionTitleLabel.string = currentCell;
    [cell addChild:cellContent];
    cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
    cell.contentSize = CGSizeMake(1.f, 50.f);
  } else {
    NSDictionary *currentGame = _allCells[index];
    PlayerCell *cellContent = (PlayerCell *)[CCBReader load:@"PlayerCell"];
    cellContent.nameLabel.string = getOpponentName(currentGame);
    [cell addChild:cellContent];
    cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
    cell.contentSize = CGSizeMake(1.f, 50.f);
    
    if (index < [[UserInfo sharedUserInfo].gamesYourTurn count]) {
      cellContent.actionLabel.string = @"PLAY";
    } else if (index < [[UserInfo sharedUserInfo].gamesTheirTurn count]) {
      cellContent.actionLabel.string = @"SHOW";
    } else if (index < [[UserInfo sharedUserInfo].gamesCompleted count]) {
      cellContent.actionLabel.string = @"REMATCH";
    }
  }
  
  return cell;
}

- (float) tableView:(CCTableView*)tableView heightForRowAtIndex:(NSUInteger) index {
  return 50;
}

- (NSUInteger) tableViewNumberOfRows:(CCTableView*) tableView {
  return [_allCells count];
}

- (void)tableViewCellSelected:(CCTableViewCell*)sender {
    CCLOG(@"Index selected:%d", _tableView.selectedRow);
  [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

#pragma mark - Button Callbacks

- (void)playNow {
  [MGWU getRandomGameWithCallback:@selector(receivedRandomGame:) onTarget:self];
}

@end
