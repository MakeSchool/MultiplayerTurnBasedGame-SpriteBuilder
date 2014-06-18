//
//  GameCell.h
//  mgwuSDK
//
//  Created by Ashutosh Desai on 9/6/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MGWUGameCell : UITableViewCell
{
	NSDictionary *game;
	UIImageView *iv;
	UILabel *name;
	UILabel *description;
	BOOL dark;
}

@property UITableView *tableView;
@property NSIndexPath *indexPath;

- (id)initWithDark:(BOOL)d style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setGame:(NSDictionary*)g;
+ (float)height;

@end
