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
#import "GameScene.h"
#import "UserInfo.h"
#import "SectionCell.h"

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

#pragma mark - Button Callbacks

- (void)reload {
	// update data with newest from MGWU server
	[[UserInfo sharedUserInfo] refreshWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

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

- (void)playNow {
	if ([[[UserInfo sharedUserInfo] gamesYourTurn] count] > 0)
	{
		/*
		 1) If you have open games on which it is your turn to play, play one of these games
		 */
		NSDictionary *game = [[UserInfo sharedUserInfo] gamesYourTurn][0];
		
		CCScene *scene = [CCBReader loadAsScene:@"GameScene"];
		GameScene *gameScene = scene.children[0];
		gameScene.game = game;
		[[CCDirector sharedDirector] pushScene:scene];
		
	} else
	{
		/*
		 2) Start a random match
		 */
		[MGWU getRandomGameWithCallback:@selector(receivedRandomGame:) onTarget:self];
	}
}

- (void)receivedRandomGame:(NSMutableDictionary *)game {
	// when we reveive a random game, first set the opponent and opponent name
    [UserInfo setOpponentAndOpponentName:game];
    
    // present the GameScene with this game
	CCScene *scene = [CCBReader loadAsScene:@"GameScene"];
	GameScene *gameScene = scene.children[0];
	gameScene.game = game;
	[[CCDirector sharedDirector] pushScene:scene];
}

- (void)showFriendList {
	// switch to the friendlist
	CCScene *friendListScene = [CCBReader loadAsScene:@"FriendListScene"];
	[[CCDirector sharedDirector] pushScene:friendListScene];
}

#pragma mark - CCTableViewDataSource Protocol

//This method is called automatically by the CCTableView to create cells
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
		cellContent.nameLabel.string = [UserInfo shortNameFromName:currentGame[@"opponentName"]];
		cellContent.player = @{@"username":currentGame[@"opponent"]};
		[cell addChild:cellContent];
		cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
		cell.contentSize = CGSizeMake(1.f, 50.f);
    
		if ([currentGame[@"gamestate"] isEqualToString:@"ended"]) {
			if ([currentGame[@"gamedata"][@"winner"] isEqualToString:currentGame[@"opponent"]])
				cellContent.actionLabel.string = @"LOST";
			else
				cellContent.actionLabel.string = @"WON";
		} else {
			if ([currentGame[@"turn"] isEqualToString:currentGame[@"opponent"]]) {
				// if the current player is waiting, set the action to "VIEW"
				cellContent.actionLabel.string = @"VIEW";
			} else {
				// if it's the player's turn in the the game, set the action to be "PLAY"
				cellContent.actionLabel.string = @"PLAY";
			}
		}
	}
	
	return cell;
}

//This method is called automatically by the CCTableView to create cells
- (float) tableView:(CCTableView*)tableView heightForRowAtIndex:(NSUInteger) index {
	return 50;
}

//This method is called automatically by the CCTableView to create cells
- (NSUInteger) tableViewNumberOfRows:(CCTableView*) tableView {
	return [_allCells count];
}

//This method is called automatically by the CCTableView when cells are tapped
- (void)tableViewCellSelected:(CCTableViewCell*)sender {
	NSInteger index = _tableView.selectedRow;
	
	id currentCell = _allCells[index];
  
	if ([currentCell isKindOfClass:[NSString class]]) {
		// this is a section and we don't need user interaction
		return;
	} else {
		// if a game cell was tapped, pick the selected game from the '_allCells' array
		NSDictionary *selectedGame = _allCells[index];
    
		CCScene *scene = [CCBReader loadAsScene:@"GameScene"];
		GameScene *gameScene = scene.children[0];
		gameScene.game = selectedGame;
		[[CCDirector sharedDirector] pushScene:scene];
  }
}



@end
