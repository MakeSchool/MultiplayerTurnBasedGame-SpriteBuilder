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

@implementation MainScene {
    CCNode *_tableViewContentNode;
    CCTableView *_tableView;
}

- (void)didLoadFromCCB {
    _tableView = [[CCTableView alloc] init];
    [_tableViewContentNode addChild:_tableView];
    _tableView.contentSizeType = CCSizeTypeNormalized;
    _tableView.contentSize = CGSizeMake(1.f, 1.f);
    _tableView.dataSource = self;
    [_tableView setTarget:self selector:@selector(tableViewCellSelected:)];
}

- (void)onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    
    [MGWU getMyInfoWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

#pragma mark - MGWUSDK Callbacks

- (void)loadedUserInfo:(NSDictionary *)userInfo {
    NSLog(@"Test");
}

#pragma mark - CCTableViewDataSource Protocol

- (CCTableViewCell*) tableView:(CCTableView*)tableView nodeForRowAtIndex:(NSUInteger) index {
    CCTableViewCell *cell = [[CCTableViewCell alloc] init];
    PlayerCell *cellContent = (PlayerCell *)[CCBReader load:@"PlayerCell"];
    cellContent.nameLabel.string = [NSString stringWithFormat:@"Player %d", index];
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

- (void)tableViewCellSelected:(CCTableViewCell*)sender {
    CCLOG(@"Index selected:%d", _tableView.selectedRow);
}

@end
