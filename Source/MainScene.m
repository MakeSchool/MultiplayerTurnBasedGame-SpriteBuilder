//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "CCTableView.h"

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

#pragma mark - CCTableViewDataSource Protocol

- (CCTableViewCell*) tableView:(CCTableView*)tableView nodeForRowAtIndex:(NSUInteger) index {
    CCTableViewCell *cell = [[CCTableViewCell alloc] init];
    cell.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitPoints);
    cell.contentSize = CGSizeMake(1.f, 50.f);
    
    CCNodeColor *colorNode = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.5 green:1.f blue:0.5]];
    colorNode.contentSizeType = CCSizeTypeNormalized;
    colorNode.contentSize = CGSizeMake(1.f, 1.f);
    [cell addChild:colorNode];
    
    return cell;
}

- (NSUInteger) tableViewNumberOfRows:(CCTableView*) tableView {
    return 10;
}

- (void)tableViewCellSelected:(CCTableViewCell*)sender {
    CCLOG(@"Index selected:%d", _tableView.selectedRow);
}

@end
