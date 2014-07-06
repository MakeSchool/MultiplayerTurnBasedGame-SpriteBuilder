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
#import "Constants.h"

@implementation MainScene {
  // container node for the table view
  CCNode *_tableViewContentNode;
  CCTableView *_tableView;
  // array that will hold all cells in the table view
  NSMutableArray *_allCells;
}

#pragma mark - Lifecycle

- (void)dealloc {
  // remove table view delegate when this class is deallocated
  [_tableView setTarget:nil selector:nil];
}

- (void)didLoadFromCCB {
  // setup table view
  _tableView = [[CCTableView alloc] init];
  [_tableViewContentNode addChild:_tableView];
  _tableView.contentSizeType = CCSizeTypeNormalized;
  _tableView.contentSize = CGSizeMake(1.f, 1.f);
  [_tableView setTarget:self selector:@selector(tableViewCellSelected:)];

  // create an array that will hold all cells in the table view
  _allCells = [NSMutableArray array];

  _tableView.dataSource = self;
}

- (void)onEnterTransitionDidFinish {
  [super onEnterTransitionDidFinish];
  
  // whenever MainScene becomes visible, reload data from server
  [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

#pragma mark - MGWUSDK Callbacks

- (void)loadedUserInfo:(NSDictionary *)userInfo {
  _allCells = [NSMutableArray array];
  
  // setup sections in the tableview and add games into the according sections
  [_allCells addObject:@"Your Turn"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesYourTurn];
  [_allCells addObject:@"Waiting on"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesTheirTurn];
  [_allCells addObject:@"Completed"];
  [_allCells addObjectsFromArray:[UserInfo sharedUserInfo].gamesCompleted];
  
  // after "_allCells" is set up entirely, call "reloadData" to update the table view with the latest information
  [_tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)receivedRandomGame:(NSDictionary *)gameInfo {
  // when we reveive a random game, present the PreMatchScene with this game
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
    // Current cell is a section, create a "SectionCell" for it
    SectionCell *cellContent = (SectionCell *)[CCBReader load:@"SectionCell"];
    cellContent.sectionTitleLabel.string = currentCell;
    [cell addChild:cellContent];
    cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
    cell.contentSize = CGSizeMake(1.f, 50.f);
  } else {
    // Current cell represents a match. Create a "PlayerCell"
    NSDictionary *currentGame = _allCells[index];
    PlayerCell *cellContent = (PlayerCell *)[CCBReader load:@"PlayerCell"];
    cellContent.nameLabel.string = friendNameForUsername(getOpponentName(currentGame));
    cellContent.playerUsername = getOpponentName(currentGame);
    [cell addChild:cellContent];
    cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
    cell.contentSize = CGSizeMake(1.f, 50.f);
    
    if ([currentGame[@"gamestate"] isEqualToString:GAME_STATE_IN_PROGRESS]) {
      if (isPlayersTurn(currentGame)) {
        // if it's the player's turn in the the game, set the action to be "PLAY"
        cellContent.actionLabel.string = @"PLAY";
      } else {
        // if the current player is waiting, set the action to "SHOW"
        cellContent.actionLabel.string = @"SHOW";
      }
    } else if ([currentGame[@"gamestate"] isEqualToString:GAME_STATE_COMPLETED]) {
      // if game is completed, set action to "REMATCH"
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
    // if a game cell was tapped, pick the selected game from the '_allCells' array
    NSDictionary *selectedGame = _allCells[index];
    
    if (isCurrentRoundCompleted(selectedGame) && isPlayersTurn(selectedGame) && !isGameCompleted(selectedGame)) {
      // present results of previous round
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

- (void)reload {
  // update data with newest from MGWU server
  [[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

- (void)playNow {
  // get a list of friends against which we don't have an open match
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
  // switch to the friendlist
  CCScene *friendListScene = [CCBReader loadAsScene:@"FriendListScene"];
  [[CCDirector sharedDirector] pushScene:friendListScene];
}

@end
