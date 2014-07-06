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
#import <mgwuSDK/MGWU.h>
#import "PreMatchScene.h"
#import "UserInfo.h"
#import "GameDataUtils.h"
#import "SectionCell.h"
#import "RoundResultScene.h"

@implementation MainScene {
    CCNode *_tableViewContentNode;
    CCTableView *_tableView;
    CCTextField *_textField;
  
    NSMutableArray *_allCells;
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
  
    _allCells = [NSMutableArray array];

    _tableView.dataSource = self;
}

- (void)onEnterTransitionDidFinish {
  [super onEnterTransitionDidFinish];
  
  [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

#pragma mark - MGWUSDK Callbacks

- (void)loadedUserInfo:(NSDictionary *)userInfo {
  _allCells = [NSMutableArray array];
  
  [_allCells addObject:@"Your Turn"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesYourTurn];
  [_allCells addObject:@"Waiting on"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesTheirTurn];
  [_allCells addObject:@"Completed"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesCompleted];
  
  
  [_tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
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
    cellContent.nameLabel.string = friendNameForUsername(getOpponentName(currentGame));
    cellContent.playerUsername = getOpponentName(currentGame);
    [cell addChild:cellContent];
    cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
    cell.contentSize = CGSizeMake(1.f, 50.f);
    
    //TODO: refactor this
    if (index < [[UserInfo sharedUserInfo].gamesYourTurn count] + 1) {
      cellContent.actionLabel.string = @"PLAY";
    } else if (index < [[UserInfo sharedUserInfo].gamesYourTurn count] + [[UserInfo sharedUserInfo].gamesTheirTurn count]+2) {
      cellContent.actionLabel.string = @"SHOW";
    } else if (index < [[UserInfo sharedUserInfo].gamesCompleted count] + [[UserInfo sharedUserInfo].gamesYourTurn count] + [[UserInfo sharedUserInfo].gamesTheirTurn count] +3) {
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
  NSInteger index = _tableView.selectedRow;
  
  id currentCell = _allCells[index];
  
  if ([currentCell isKindOfClass:[NSString class]]) {
    // this is a section and we don't need user interaction
    return;
  } else {
    NSDictionary *selectedGame = _allCells[index];
    
    if (isCurrentRoundCompleted(selectedGame) && isPlayersTurn(selectedGame) && !isGameCompleted(selectedGame)) {
      // present results of previous game
      CCScene *gameResultScene = [CCBReader loadAsScene:@"RoundResultScene"];
      [gameResultScene.children[0] setGame:selectedGame];
      // after presenting round results switch to the prematch scene
      [gameResultScene.children[0] setNextScene:RoundResultSceneNextScenePreMatchScene];
      
      CCTransition *pushTransition = [CCTransition transitionPushWithDirection:CCTransitionDirectionLeft duration:0.3f];
      [[CCDirector sharedDirector] pushScene:gameResultScene withTransition:pushTransition];
    } else {
      // show prematch scene, because player needs to complete this round
      CCScene *scene = [CCBReader loadAsScene:@"PreMatchScene"];
      PreMatchScene *prematchScene = scene.children[0];
      prematchScene.game = selectedGame;
      [[CCDirector sharedDirector] pushScene:scene];
    }
  }
}

#pragma mark - Button Callbacks

- (void)playNow {
  NSArray *openFriends = friendsWithoutOpenMatches();

  
  if ([[[UserInfo sharedUserInfo] gamesYourTurn] count] > 0)
  {
    /*
     1) If you have open games on which it is your turn to play, play one of these games
     */
    NSDictionary *game = [[[UserInfo sharedUserInfo] gamesYourTurn] objectAtIndex:0];
   
    CCScene *scene = [CCBReader loadAsScene:@"PreMatchScene"];
    PreMatchScene *prematchScene = scene.children[0];
    prematchScene.game = game;
    [[CCDirector sharedDirector] pushScene:scene];
    
  } else if ([openFriends count] > 0)
  {
    /*
     2) If you have friends playing that you are currently not having a match with, challenge them
     */
    int randPlayer = arc4random_uniform([openFriends count]);
    NSString *playerUsername = openFriends[randPlayer];
    NSDictionary *game = @{@"opponent":playerUsername};
    
    CCScene *scene = [CCBReader loadAsScene:@"PreMatchScene"];
    PreMatchScene *prematchScene = scene.children[0];
    prematchScene.game = game;
    [[CCDirector sharedDirector] pushScene:scene];

  } else
  {
    /*
     3) Start a random match
     */
    [MGWU getRandomGameWithCallback:@selector(receivedRandomGame:) onTarget:self];
  }
}

- (void)showFriendList {
  CCScene *friendListScene = [CCBReader loadAsScene:@"FriendListScene"];
  [[CCDirector sharedDirector] pushScene:friendListScene];
}

@end
