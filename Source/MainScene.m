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
}

- (void)didLoadFromCCB {
    CCTableView *tableView = [[CCTableView alloc] init];
    [_tableViewContentNode addChild:tableView];
    tableView.contentSizeType = CCSizeTypeNormalized;
    tableView.contentSize = CGSizeMake(1.f, 1.f);
    tableView.dataSource = self;
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

//- (float) tableView:(CCTableView*)tableView heightForRowAtIndex:(NSUInteger) index;

@end
